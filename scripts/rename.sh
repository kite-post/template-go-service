#!/usr/bin/env bash
# Перетворює шаблон у репозиторій конкретного сервіса: ім'я модуля, імпорти,
# ім'я сервіса у конфігу та ім'я образу.
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Вкажи ім'я сервіса, наприклад scan-service" >&2
  exit 1
fi
name="$1"
org="${ORG:-kite-post}"

if [[ ! "$name" =~ ^[a-z][a-z0-9-]*$ ]]; then
  echo "Ім'я сервіса — малі літери, цифри і дефіси: scan-service" >&2
  exit 1
fi

echo "Сервіс: $name"
echo "Модуль: github.com/$org/$name"

while IFS= read -r f; do
  perl -pi -e "
    s{github\.com/kite-post/service-template}{github.com/$org/$name}g;
    s/service-template/$name/g;
  " "$f"
done < <(find . -type f \
  \( -name '*.go' -o -name 'go.mod' -o -name '*.yml' -o -name '*.yaml' -o -name '*.md' \) \
  -not -path './.git/*' -not -path './bin/*')

command -v go >/dev/null 2>&1 && go mod tidy || true

echo
echo "Готово. Далі:"
echo "  make lint test"
echo "  git add -A && git commit -m \"Перейменувати шаблон у $name\""
