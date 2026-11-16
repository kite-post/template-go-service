// Команда сервіса: читає конфіг з оточення, піднімає HTTP і коректно гасне.
package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/kite-post/service-template/internal/httpapi"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{Level: level()}))
	slog.SetDefault(logger)

	cfg := httpapi.Config{
		Service: env("SERVICE_NAME", "service-template"),
		Version: env("KITE_IMAGE_TAG", "dev"),
	}

	server := &http.Server{
		Addr:              ":" + env("PORT", "8080"),
		Handler:           httpapi.New(cfg),
		ReadHeaderTimeout: 5 * time.Second,
	}

	// SIGTERM приходить від Docker при зупинці контейнера — доживаємо запити.
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	go func() {
		logger.Info("сервіс піднявся", "service", cfg.Service, "addr", server.Addr)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			logger.Error("сервер упав", "err", err)
			stop()
		}
	}()

	<-ctx.Done()
	logger.Info("зупиняюся")

	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := server.Shutdown(shutdownCtx); err != nil {
		logger.Error("не вдалося зупинитися чисто", "err", err)
		os.Exit(1)
	}
}

func env(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func level() slog.Level {
	var l slog.Level
	if err := l.UnmarshalText([]byte(env("LOG_LEVEL", "info"))); err != nil {
		return slog.LevelInfo
	}
	return l
}
