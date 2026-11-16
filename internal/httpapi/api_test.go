package httpapi_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/kite-post/service-template/internal/httpapi"
)

func TestInfoVidpovidae(t *testing.T) {
	t.Parallel()

	handler := httpapi.New(httpapi.Config{Service: "service-template", Version: "v1.2.3"})
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/api/v1/info", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("статус %d, а мав бути %d", rec.Code, http.StatusOK)
	}

	var body map[string]string
	if err := json.NewDecoder(rec.Body).Decode(&body); err != nil {
		t.Fatalf("тіло не розбирається: %v", err)
	}
	if body["service"] != "service-template" {
		t.Errorf("service = %q", body["service"])
	}
	if body["version"] != "v1.2.3" {
		t.Errorf("version = %q", body["version"])
	}
}

func TestHealthzKazheUP(t *testing.T) {
	t.Parallel()

	handler := httpapi.New(httpapi.Config{})
	rec := httptest.NewRecorder()
	handler.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/healthz", nil))

	if rec.Code != http.StatusOK {
		t.Fatalf("статус %d", rec.Code)
	}
}
