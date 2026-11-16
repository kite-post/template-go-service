# syntax=docker/dockerfile:1

# ── Збірка ────────────────────────────────────────────────────────────────────
FROM golang:1.25-alpine AS build
WORKDIR /build

# Залежності окремим шаром — go.mod змінюється рідше за код.
COPY go.mod go.sum* ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY . .
# Статичний бінарник без CGO: у фінальному образі немає ні libc, ні shell.
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=linux go build \
    -trimpath -ldflags="-s -w" -o /out/server ./cmd/server

# ── Запуск ────────────────────────────────────────────────────────────────────
FROM gcr.io/distroless/static-debian12:nonroot AS runtime

COPY --from=build /out/server /server

USER nonroot:nonroot
EXPOSE 8080

ENTRYPOINT ["/server"]
