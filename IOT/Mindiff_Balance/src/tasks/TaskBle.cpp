#include "TaskBle.h"
#include "../AppState.h"

#ifndef NO_BLE

#include "BleManager.h"
#include "../GlobalState.h"

static BleManager        _ble;
static TaskHandle_t      _handle  = nullptr;
static SemaphoreHandle_t _stopSem = nullptr;

static void onCredentials(const String& json) {
    strncpy(gCredsJson, json.c_str(), sizeof(gCredsJson) - 1);
    xSemaphoreGive(credsSem); // débloque setup() qui attend les credentials
}

static void run(void* param) {
    const char* name = (const char*)param;
    _ble.beginProvisioning(name, onCredentials);
    gState.update([](BalanceStatus& s) { s.bleReady = true; });

    xSemaphoreTake(_stopSem, portMAX_DELAY); // attend stopTaskBle()

    _ble.stopProvisioning();
    gState.update([](BalanceStatus& s) { s.bleReady = false; });
    vTaskDelete(nullptr);
}

void startTaskBle(const char* deviceName) {
    _stopSem = xSemaphoreCreateBinary();
    xTaskCreatePinnedToCore(run, "BLE", 4096, (void*)deviceName, 2, &_handle, 0);
}

void stopTaskBle() {
    if (_stopSem) xSemaphoreGive(_stopSem);
}

#else // NO_BLE : stubs silencieux pour Wokwi (pas de hardware BLE)

void startTaskBle(const char*) {}
void stopTaskBle() {}

#endif
