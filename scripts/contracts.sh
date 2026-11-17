#!/usr/bin/env bash
# Підключає kite-contracts за тегом: make contracts V=0.2.0 розставляє версію в
# Makefile і go.mod. Без V — просто підтягує поточну версію. Цим самим викликом
# користується CI, коли kite-contracts випускає новий тег.
set -euo pipefail

v="${1:?вкажи версію: scripts/contracts.sh 0.2.0}"
printf '%s' "$v" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' \
  || { echo "contracts: версія «$v» має бути вигляду 1.2.3" >&2; exit 1; }
module="github.com/${ORG:-kite-post}/kite-contracts"

# Правка атомарна: якщо тег не знайдеться, файли повертаються як були, і
# Makefile не розійдеться з маніфестом.
backup="$(mktemp -d)"
for f in Makefile go.mod go.sum; do [ -f "$f" ] && cp "$f" "$backup/"; done
restore() { for f in Makefile go.mod go.sum; do [ -f "$backup/$f" ] && cp "$backup/$f" "$f"; done; }
trap 'rc=$?; [ $rc -ne 0 ] && restore; exit $rc' EXIT

perl -pi -e "s|^CONTRACTS_VERSION \?= .*|CONTRACTS_VERSION ?= $v|" Makefile
go get "$module@v$v"
go mod tidy
echo "$module v$v у go.mod."
echo "Структури, клієнт і реєстр подій — у пакеті kite; своїх копій схем сервіс не тримає."
