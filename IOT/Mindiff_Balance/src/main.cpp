#include <Arduino.h>
#include <ArduinoJson.h>

#include "Scale.h"
#include "Display.h"
#include "WifiManager.h"
#include "ApiClient.h"
#include "ConfigManager.h"
#include "BalanceStatus.h"

#include "GlobalState.h"
#include "AppState.h"
#include "tasks/TaskDisplay.h"
#include "tasks/TaskScale.h"
#include "tasks/TaskApi.h"
#include "tasks/TaskBle.h"
#include "tasks/TaskCalibration.h"

#ifndef DEFAULT_CALIB_FACTOR
#define DEFAULT_CALIB_FACTOR 1000.0f
#endif

// ─── Config hardware ──────────────────────────────────────────────────────────
static const int PIN_DOUT = 13;
static const int PIN_SCK  = 14;

// ─── Objets hardware ─────────────────────────────────────────────────────────
static Scale         scale(PIN_DOUT, PIN_SCK);
static Display       display;
static WifiManager   wifi;
static ConfigManager configMgr;
static ApiClient*    api = nullptr;

// ─── Démarre toutes les tâches opérationnelles ────────────────────────────────
static void startOperationalTasks() {
    startTaskScale(&scale);
    startTaskApi(&api);
    startTaskCalibration(&scale, &display, &configMgr);

    gState.update([](BalanceStatus& s) {
        s.state  = BalanceState::OPERATIONAL;
        s.wifiOk = true;
    });
    Serial.println("[Boot] Mode operationnel");
}

// ─── Parse et sauvegarde les credentials reçus via BLE ou Serial ─────────────
static bool applyCredentials(const char* json) {
    StaticJsonDocument<512> doc;
    if (deserializeJson(doc, json) != DeserializationError::Ok) {
        Serial.println("[Boot] JSON invalide");
        return false;
    }

    const char* ssid   = doc["ssid"]     | "";
    const char* pass   = doc["password"] | "";
    const char* token  = doc["token"]    | "";
    const char* apiUrl = doc["api_url"]  | "";
    int         userId = doc["user_id"]  | -1;

    if (!ssid[0] || !token[0] || !apiUrl[0] || userId < 0) {
        Serial.println("[Boot] Champs manquants dans le JSON");
        return false;
    }

    Config cfg;
    cfg.ssid        = ssid;
    cfg.password    = pass;
    cfg.token       = token;
    cfg.apiUrl      = apiUrl;
    cfg.userId      = userId;
    cfg.calibFactor = scale.getCalibrationFactor(); // conserve la calib actuelle
    configMgr.save(cfg);
    return true;
}

// ─── Setup ────────────────────────────────────────────────────────────────────
void setup() {
    Serial.begin(115200);
    Serial.println("=== Balance boot ===");

    // 1. Init FreeRTOS (avant de créer des tâches)
    gState.init();
    initAppState();

    // 2. Init hardware avec le facteur de calibration sauvegardé si dispo
    const bool  hasConfig    = configMgr.load();
    float       calibFactor  = hasConfig ? configMgr.get().calibFactor : DEFAULT_CALIB_FACTOR;
    if (calibFactor <= 0.0f || calibFactor > 100.0f) {
        calibFactor = DEFAULT_CALIB_FACTOR;
        if (hasConfig) {
            Config cfg = configMgr.get();
            cfg.calibFactor = calibFactor;
            configMgr.save(cfg);
        }
    }
    scale.begin(calibFactor);
    Serial.printf("[Boot] Scale OK (calib: %.1f)\n", calibFactor);

    if (!display.begin()) Serial.println("[Boot] Display FAIL");
    else                  Serial.println("[Boot] Display OK");

    // 3. TaskDisplay démarre immédiatement (montre la progression du boot)
    startTaskDisplay(&display);

    // ── 4. Credentials en NVS → connexion directe ────────────────────────────
    if (configMgr.isProvisioned()) {
        const Config& cfg = configMgr.get();
        gState.update([&cfg](BalanceStatus& s) {
            s.state = BalanceState::CONNECTING;
            s.ssid  = cfg.ssid;
        });

        Serial.printf("[Boot] Connexion à %s...\n", cfg.ssid.c_str());
        if (wifi.connect(cfg.ssid, cfg.password)) {
            api = new ApiClient(cfg.apiUrl, cfg.token, cfg.userId);
            startOperationalTasks();
            return;
        }

        Serial.println("[Boot] WiFi echec → reset config");
        configMgr.clear();
    }

    // ── 5. Provisioning : fenêtre Serial 5s ──────────────────────────────────
    gState.update([](BalanceStatus& s) {
        s.state       = BalanceState::PROVISIONING;
        s.serialReady = true;
        s.bleReady    = false;
    });

    Serial.println("[Boot] Envoie le JSON dans les 5s :");
    Serial.println("{\"ssid\":\"...\",\"password\":\"...\",\"token\":\"...\",\"api_url\":\"...\",\"user_id\":1}");

    unsigned long t0 = millis();
    while (millis() - t0 < 5000) {
        if (Serial.available()) {
            String line = Serial.readStringUntil('\n');
            line.trim();
            if (line.startsWith("{")) {
                Serial.println("[Boot] Credentials via Serial");
                strncpy(gCredsJson, line.c_str(), sizeof(gCredsJson) - 1);
                xSemaphoreGive(credsSem);
                break;
            }
        }
        delay(50);
    }

    // ── 6. Pas de Serial → BLE ───────────────────────────────────────────────
    if (uxSemaphoreGetCount(credsSem) == 0) {
        Serial.println("[Boot] Démarrage BLE...");
        startTaskBle("Balance-ESP32");
    }

    // ── 7. Attendre les credentials (déjà donnés via Serial ou via BLE) ──────
    xSemaphoreTake(credsSem, portMAX_DELAY);
    stopTaskBle();

    if (!applyCredentials(gCredsJson)) {
        Serial.println("[Boot] Credentials invalides → redémarrage");
        delay(1000);
        ESP.restart();
        return;
    }

    // ── 8. Connexion WiFi avec les nouveaux credentials ───────────────────────
    const Config& cfg = configMgr.get();
    gState.update([&cfg](BalanceStatus& s) {
        s.state = BalanceState::CONNECTING;
        s.ssid  = cfg.ssid;
    });

    Serial.printf("[Boot] Connexion à %s...\n", cfg.ssid.c_str());
    if (!wifi.connect(cfg.ssid, cfg.password)) {
        configMgr.clear();
        Serial.println("[Boot] WiFi echec → redémarrage");
        delay(1000);
        ESP.restart();
        return;
    }

    api = new ApiClient(cfg.apiUrl, cfg.token, cfg.userId);
    startOperationalTasks();
}

// ─── Loop : reconnexion WiFi ─────────────────────────────────────────────────
// Toute la logique métier est dans les tâches.
// Loop gère uniquement la reconnexion WiFi toutes les 5s.
void loop() {
    if (gState.state() != BalanceState::OPERATIONAL) {
        vTaskDelay(pdMS_TO_TICKS(1000));
        return;
    }

    if (!wifi.isConnected()) {
        gState.update([](BalanceStatus& s) {
            s.wifiOk    = false;
            s.lastEvent = "Reconnexion...";
        });

        bool ok = wifi.reconnect(5000);
        gState.update([ok](BalanceStatus& s) { s.wifiOk = ok; });

        Serial.println(ok ? "[WiFi] Reconnecte" : "[WiFi] Reconnexion echouee");
    }

    vTaskDelay(pdMS_TO_TICKS(5000));
}
