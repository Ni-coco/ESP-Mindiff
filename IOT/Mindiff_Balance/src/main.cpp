#include <Arduino.h>

#include "config/AppConfig.h"
#include "state/GlobalState.h"
#include "state/AppState.h"
#include "protocol/CalibCommand.h"

#include "Scale.h"
#include "Display.h"
#include "WifiManager.h"
#include "ConfigManager.h"
#include "ApiClient.h"

#include "tasks/ScaleReader.h"
#include "tasks/ApiSender.h"
#include "tasks/CalibHandler.h"
#include "tasks/CommandsHandler.h"
#include "tasks/BootManager.h"
#include "tasks/WifiMonitor.h"

// ─────────────────────────────────────────────────────────────────────────────
// STATE  (définis ici, déclarés extern dans include/state/)
// ─────────────────────────────────────────────────────────────────────────────
GlobalState       gState;
SemaphoreHandle_t scaleMutex    = nullptr;
SemaphoreHandle_t displayMutex  = nullptr;
QueueHandle_t     qStableWeight = nullptr;
QueueHandle_t     qCalibCmd     = nullptr;
SemaphoreHandle_t credsSem      = nullptr;
char              gCredsJson[512] = {};

// ─────────────────────────────────────────────────────────────────────────────
// HARDWARE
// ─────────────────────────────────────────────────────────────────────────────
Scale         scale(PIN_DOUT, PIN_SCK);
Display       display;
WifiManager   wifi;
ConfigManager configMgr;
ApiClient*    api = nullptr;

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSANTS  (dépendances injectées dans le constructeur)
// ─────────────────────────────────────────────────────────────────────────────
ScaleReader     scaleReader(scale);
ApiSender       apiSender(api);
CalibHandler    calibHandler(scale, display, configMgr);
CommandsHandler commandsHandler;
BootManager     bootManager(wifi, configMgr, scale, api);
WifiMonitor     wifiMonitor(wifi);

// ─────────────────────────────────────────────────────────────────────────────
// TÂCHES  (thin wrappers — toute la logique est dans les composants)
// ─────────────────────────────────────────────────────────────────────────────
void taskDisplay(void*) {
    while (true) {
        xSemaphoreTake(displayMutex, portMAX_DELAY);
        display.render(gState.snapshot());
        xSemaphoreGive(displayMutex);
        vTaskDelay(pdMS_TO_TICKS(DELAY_DISPLAY_MS));
    }
}

void taskScale(void*) {
    while (true) {
        scaleReader.loop();
        vTaskDelay(pdMS_TO_TICKS(DELAY_SCALE_MS));
    }
}

void taskApi(void*) {
    while (true) { apiSender.loop(); }       // bloque sur la queue
}

void taskCalibration(void*) {
    while (true) { calibHandler.loop(); }    // bloque sur la queue
}

void taskCommands(void* param) {
    commandsHandler.begin((const char*)param);
    while (true) {
        commandsHandler.loop();
        vTaskDelay(pdMS_TO_TICKS(DELAY_BLE_NOTIFY_MS));
    }
}

// taskBoot gère deux phases :
//   - avant OPERATIONAL : appelle bootManager.loop() rapidement (50ms)
//   - après OPERATIONAL : appelle wifiMonitor.loop() lentement (5s)
void taskBoot(void*) {
    while (true) {
        if (gState.state() == BalanceState::OPERATIONAL) {
            wifiMonitor.loop();
            vTaskDelay(pdMS_TO_TICKS(DELAY_WIFI_MONITOR_MS));
        } else {
            bootManager.loop();
            vTaskDelay(pdMS_TO_TICKS(50));
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETUP / LOOP
// ─────────────────────────────────────────────────────────────────────────────
void setup() {
    Serial.begin(115200);
    Serial.println("=== Balance boot ===");

    // State
    gState.init();
    scaleMutex    = xSemaphoreCreateMutex();
    displayMutex  = xSemaphoreCreateMutex();
    qStableWeight = xQueueCreate(1, sizeof(float));
    qCalibCmd     = xQueueCreate(4, sizeof(CalibCommand));
    credsSem      = xSemaphoreCreateBinary();

    // Hardware
    configMgr.load();
    float calib = configMgr.isProvisioned() ? configMgr.get().calibFactor : DEFAULT_CALIB_FACTOR;
    scale.begin(calib);
    display.begin();

    // Composants
    bootManager.begin();   // pré-remplit credentials si credentials.h est défini (Wokwi)

    // Tâches — toutes créées ici, elles gèrent leur propre état de readiness
    xTaskCreatePinnedToCore(taskDisplay,     "Display",  STACK_DISPLAY,  nullptr,               1, nullptr, 0);
    xTaskCreatePinnedToCore(taskCommands,    "Commands", STACK_COMMANDS, (void*)"Balance-ESP32", 2, nullptr, 0);
    xTaskCreatePinnedToCore(taskScale,       "Scale",    STACK_SCALE,    nullptr,               2, nullptr, 1);
    xTaskCreatePinnedToCore(taskApi,         "Api",      STACK_API,      nullptr,               1, nullptr, 0);
    xTaskCreatePinnedToCore(taskCalibration, "Calib",    STACK_CALIB,    nullptr,               1, nullptr, 1);
    xTaskCreatePinnedToCore(taskBoot,        "Boot",     STACK_BOOT,     nullptr,               1, nullptr, 1);
}

void loop() {
    vTaskDelete(NULL);
}
