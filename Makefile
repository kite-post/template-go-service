SERVICE ?= $(notdir $(CURDIR))
ORG     ?= kite-post
IMAGE   ?= ghcr.io/$(ORG)/$(SERVICE)
TAG     ?= dev

.DEFAULT_GOAL := help
.PHONY: help build lint fmt tidy test test-it verify image run up down clean contracts rename

help: ## Показати цілі
	@grep -hE '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

build: ## Зібрати бінарник у ./bin
	CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o bin/server ./cmd/server

lint: ## gofmt, go vet, golangci-lint
	@unformatted="$$(gofmt -l . | grep -v '^vendor/' || true)"; \
	if [ -n "$$unformatted" ]; then echo "Не відформатовано:"; echo "$$unformatted"; exit 1; fi
	go vet ./...
	@command -v golangci-lint >/dev/null 2>&1 \
		&& golangci-lint run \
		|| echo "golangci-lint не встановлений локально — у CI він є."

fmt: ## Відформатувати код
	gofmt -w .

tidy: ## Узгодити go.mod і go.sum
	go mod tidy

test: ## Юніт-тести
	go test -race -short ./...

test-it: ## Усі тести, включно з інтеграційними
	go test -race -covermode=atomic -coverprofile=coverage.out ./...

verify: lint test-it ## Усе, що робить CI

image: ## Зібрати образ локально
	docker build -t $(IMAGE):$(TAG) .

run: ## Запустити локально
	go run ./cmd/server

up: image ## Підняти образ у контейнері на 8080
	docker run --rm -p 8080:8080 --name $(SERVICE) $(IMAGE):$(TAG)

down: ## Зупинити контейнер
	-docker rm -f $(SERVICE)

clean: ## Прибрати артефакти збірки
	go clean
	rm -f coverage.out
	rm -rf ./bin

contracts: ## Згенерувати клієнтів і структури подій з kite-contracts
	@echo "kite-contracts ще не підключено до цього сервіса."
	@echo "Підключення: go-модуль github.com/$(ORG)/kite-contracts, закріплений за тегом (5.4, п. 6),"
	@echo "далі розкоментуй ціль contracts-check нижче — CI почне її проганяти."

# contracts-check: ## Перевірити сумісність зі схемами kite-contracts
# 	go run github.com/$(ORG)/kite-contracts/cmd/verify@latest ./...

rename: ## Перейменувати шаблон: make rename NAME=scan-service
	@test -n "$(NAME)" || (echo "Вкажи ім'я: make rename NAME=scan-service"; exit 1)
	@bash scripts/rename.sh "$(NAME)"
