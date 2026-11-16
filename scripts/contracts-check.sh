#!/usr/bin/env bash
# Перевіряє, що сервіс підключає kite-contracts як залежність, закріплену за
# тегом, і не тримає копій схем у себе (5.4, п. 6). Цю ціль проганяє CI.
set -euo pipefail

want="${1:?вкажи версію: scripts/contracts-check.sh 0.1.0}"
module="github.com/kite-post/kite-contracts"

fail() {
  echo "contracts-check: $1" >&2
  exit 1
}

# 1. Залежність оголошена і закріплена за тим самим тегом, що в Makefile.
have="$(go list -m -f '{{.Version}}' "$module" 2>/dev/null || true)"
[ -n "$have" ] || fail "залежності $module немає в go.mod — проганяй make contracts"
[ "$have" = "v$want" ] || fail "go.mod закріплений за $have, а Makefile — за v$want"

# 2. Ніяких replace: інакше сервіс збирається не з того, що в теґу.
if go list -m -f '{{if .Replace}}replaced{{end}}' "$module" | grep -q replaced; then
  fail "$module підмінений через replace — у main такого бути не повинно"
fi

# 3. Своїх копій схем у репозиторії бути не повинно.
copies="$(find . -path ./vendor -prune -o \
  \( -name '*.schema.json' -o -name 'openapi.yaml' -o -name 'openapi.yml' -o -name 'asyncapi.yaml' \) \
  -print 2>/dev/null || true)"
[ -z "$copies" ] || fail "у репозиторії лежать копії схем, а мають приходити залежністю:
$copies"

# 4. Код справді збирається з цими контрактами.
go build ./... || fail "сервіс не збирається з $module v$want"

echo "contracts-check: kite-contracts v$want підключений за тегом, копій схем немає."
