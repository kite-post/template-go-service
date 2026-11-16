package httpapi_test

// Перевіряє, що контракти справді приходять залежністю: і типи, і реєстр подій.
// Тест живе біля тестів HTTP-поверхні, бо окремого пакета під події в шаблоні
// ще немає — щойно сервіс почне їх читати, його варто перенести туди.

import (
	"encoding/json"
	"testing"

	"github.com/kite-post/kite-contracts/kite"
)

const statusChanged = `{
  "specversion": "1.0",
  "id": "0193c2f4-2f4a-7a7e-9c3d-2f1b8a6e4d11",
  "source": "/kite/shipment-service",
  "type": "kite.shipment.status-changed.v1",
  "subject": "KT123456785UA",
  "time": "2026-11-16T09:14:03Z",
  "kitereceivedat": "2026-11-16T09:14:04.812Z",
  "data": {
    "shipmentId": "0193c2f4-1111-7a7e-9c3d-2f1b8a6e4d00",
    "trackingNumber": "KT123456785UA",
    "statusBefore": "IN_TRANSIT",
    "statusAfter": "READY_FOR_PICKUP",
    "eventCode": "KT30",
    "transition": "T7"
  }
}`

func TestPodiiaRozbyraietsiaTypamyKontraktiv(t *testing.T) {
	t.Parallel()

	var event kite.ShipmentStatusChangedEvent
	if err := json.Unmarshal([]byte(statusChanged), &event); err != nil {
		t.Fatalf("подія не розбирається: %v", err)
	}
	if event.Data.StatusAfter != kite.ShipmentStatusREADYFORPICKUP {
		t.Errorf("стан після переходу: %s", event.Data.StatusAfter)
	}
	if event.Data.TrackingNumber != "KT123456785UA" {
		t.Errorf("номер: %s", event.Data.TrackingNumber)
	}
	if event.Kitereceivedat == nil {
		t.Error("received_at — тайбрейк порядку (8.3, п. 4) — має бути в конверті")
	}
}

func TestReiestrZnaieKudyIdePodiia(t *testing.T) {
	t.Parallel()

	meta, ok := kite.EventRegistry[kite.KiteEventTypeKiteScanRecordedV1]
	if !ok {
		t.Fatal("реєстр подій не знає kite.scan.recorded.v1")
	}
	if meta.Topic != kite.KiteTopic("scan.events") {
		t.Errorf("топік: %s", meta.Topic)
	}
	if meta.PartitionKey != "shipmentId" {
		t.Errorf("ключ розділу: %s", meta.PartitionKey)
	}
}
