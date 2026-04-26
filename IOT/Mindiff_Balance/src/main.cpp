#include <Arduino.h>
#include "GlobalState.h"
#include "ConfigManager.h"
#include "Scale.h"
#include "Display.h"
#include "BatteryMonitor.h"
#include "CommandHandler.h"
#include "WifiManager.h"
#include "ApiClient.h"

#ifdef NO_BLE
    #include "SerialComm.h"
#else
    #include "BleComm.h"
#endif

#define PIN_DOUT  13
#define PIN_SCK   14
#define PIN_BAT   34

GlobalState    state;
ConfigManager  config;
Scale          scale(PIN_DOUT, PIN_SCK, state, config);
Display        display(state);
BatteryMonitor battery(PIN_BAT, state);
WifiManager    wifi(state, config);
ApiClient      apiClient(state, config);
CommandHandler commandHandler(scale, state, config);

#ifdef NO_BLE
    SerialComm comm(state, commandHandler);
#else
    BleComm    comm(state, commandHandler);
#endif

// ── Tasks ─────────────────────────────────────────────────────────────────────

void taskScale(void*) {
    while (true) {
        scale.loop();
        vTaskDelay(pdMS_TO_TICKS(200));
    }
}

void taskDisplay(void*) {
    while (true) {
        display.render();
        vTaskDelay(pdMS_TO_TICKS(200));
    }
}

void taskBattery(void*) {
    while (true) {
        battery.loop();
        vTaskDelay(pdMS_TO_TICKS(5000));
    }
}

void taskComm(void*) {
    while (true) {
        comm.loop();
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}

void taskWifi(void*) {
    while (true) {
        wifi.loop();
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

void taskApi(void*) {
    while (true) {
        apiClient.loop();
        vTaskDelay(pdMS_TO_TICKS(500));
    }
}

// ── Setup / Loop ──────────────────────────────────────────────────────────────

void setup() {
    Serial.begin(115200);

    config.load();
    state.init();
    state.setName(config.getName());

    AppPhase initialPhase = config.getWifiSsid().length() > 0
        ? AppPhase::CONNECTING           // credentials connus → tente connexion
        : AppPhase::WAITING_CREDENTIALS; // pas de credentials → attente
    state.setPhase(initialPhase);

    scale.begin(config.getCalibFactor());
    display.begin();
    battery.begin();
    wifi.begin();
    comm.begin(config.getName());

    xTaskCreatePinnedToCore(taskScale,   "Scale",   2048, nullptr, 1, nullptr, 1);
    xTaskCreatePinnedToCore(taskDisplay, "Display", 4096, nullptr, 1, nullptr, 0);
    xTaskCreatePinnedToCore(taskBattery, "Battery", 2048, nullptr, 1, nullptr, 0);
    xTaskCreatePinnedToCore(taskComm,    "Comm",    4096, nullptr, 1, nullptr, 0);
    xTaskCreatePinnedToCore(taskWifi,    "Wifi",    4096, nullptr, 1, nullptr, 1);
    xTaskCreatePinnedToCore(taskApi,     "Api",     8192, nullptr, 1, nullptr, 1);
}

void loop() {
    vTaskDelete(NULL);
}
