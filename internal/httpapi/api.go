// Пакет httpapi тримає HTTP-поверхню сервіса: роутер і хендлери.
package httpapi

import (
	"encoding/json"
	"net/http"
)

// Config — те, що сервіс дізнається з оточення.
type Config struct {
	Service string
	Version string
}

// New збирає роутер сервіса.
func New(cfg Config) http.Handler {
	mux := http.NewServeMux()

	// Проби для compose і Kubernetes (12.3).
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "UP"})
	})
	mux.HandleFunc("GET /readyz", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{"status": "UP"})
	})
	mux.HandleFunc("GET /api/v1/info", func(w http.ResponseWriter, _ *http.Request) {
		writeJSON(w, http.StatusOK, map[string]string{
			"service": cfg.Service,
			"version": cfg.Version,
		})
	})

	return mux
}

func writeJSON(w http.ResponseWriter, status int, body any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(body); err != nil {
		// Відповідь уже пішла — лишається тільки обірвати з'єднання.
		panic(http.ErrAbortHandler)
	}
}
