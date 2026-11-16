# template-go-service

Шаблон репозиторію для Go-сервіса Kite: Go 1.27, стандартна бібліотека,
CI з одного рядка. Із нього створюються scan-service, realtime-service,
locker-service, mock-pay і sms-gateway-emu (5.6).

## Новий сервіс

```bash
gh repo create kite-post/scan-service --public --template kite-post/template-go-service
cd scan-service
make rename NAME=scan-service
git add -A && git commit -m "Перейменувати шаблон у scan-service" && git push
```

`make rename` змінює ім'я модуля, імпорти та ім'я образу. Без нього репозиторій
теж збирається і проходить CI — просто під іменем шаблону.

## Що всередині

```
cmd/server/main.go        конфіг з оточення, slog у JSON, коректна зупинка на SIGTERM
internal/httpapi          роутер: /api/v1/info, /healthz, /readyz
internal/httpapi/api_test.go  тести на httptest, без мережі
.golangci.yml             один набір лінтерів на всі Go-сервіси
Dockerfile                статичний бінарник у distroless:nonroot
Makefile                  той самий набір цілей, що й у решти репозиторіїв
.github/workflows/ci.yml  п'ять рядків: виклик спільного workflow із .github
```

Залежностей немає навмисно: роутинг методів (`GET /healthz`) умів `net/http`
з Go 1.22, а логування — `log/slog` зі стандартної бібліотеки. Коли з'являться
Kafka, MQTT або Postgres, вони приходять як перші справжні залежності сервіса.

## Команди

```bash
make build      # зібрати бінарник у ./bin
make lint       # gofmt + go vet + golangci-lint
make fmt        # відформатувати
make tidy       # узгодити go.mod і go.sum
make test       # швидкі тести (-short)
make test-it    # усі тести з покриттям
make verify     # усе, що робить CI
make image      # зібрати образ локально
make up         # підняти образ на 8080
make run        # запустити без контейнера
```

## CI

Увесь пайплайн — виклик спільного workflow з
[kite-post/.github](https://github.com/kite-post/.github): gofmt, узгодженість
`go.mod`, golangci-lint, `go vet`, тести з `-race`, збірка образу, публікація в
`ghcr.io/kite-post/<сервіс>` і PR у `kite-infra` з новою версією (12.6).

CI окремо перевіряє, що `go mod tidy` нічого не змінює — інакше `go.sum`
розповзається між репозиторіями.

## Контракти

Структури API, клієнт і типи подій CloudEvents приходять go-модулем
`github.com/kite-post/kite-contracts`, закріпленим за тегом — своїх копій
`openapi.yaml` і JSON Schema сервіс не тримає (5.4, п. 6):

```bash
make contracts        # go get github.com/kite-post/kite-contracts@v0.1.0 + tidy
make contracts-check  # версія закріплена, replace немає, копій схем немає
```

`contracts-check` проганяє спільний CI. Тест `internal/httpapi/contracts_test.go`
розбирає подію типами з контрактів і питає в реєстру, у який топік вона їде —
якщо хтось скопіює схему до себе або відв'яже залежність, він упаде першим.

У коді це виглядає так:

```go
import "github.com/kite-post/kite-contracts/kite"

meta := kite.EventRegistry[kite.KiteEventTypeKiteScanRecordedV1]
// meta.Topic == "scan.events", meta.PartitionKey == "shipmentId"
```

Порядок наскрізної зміни (5.6): спершу адитивна зміна в `kite-contracts` з
новим тегом, потім версія тут, і тільки потім продюсер починає слати нове
поле.

## Образ

Фінальний образ — `distroless/static:nonroot`: ні shell, ні пакетного
менеджера, ні root. Через це в ньому немає `curl`, тож healthcheck у compose
краще робити зовнішнім (`wget` з сусіднього контейнера) або додати власну
`/healthz`-пробу з боку оркестратора — ендпоїнт для цього вже є.
