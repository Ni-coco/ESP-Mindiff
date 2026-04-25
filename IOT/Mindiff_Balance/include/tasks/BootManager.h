#pragma once
#include "WifiManager.h"
#include "ConfigManager.h"
#include "Scale.h"
#include "ApiClient.h"
#include "state/AppState.h"
#include "state/GlobalState.h"
#include "config/AppConfig.h"

#ifdef NO_BLE
#include "credentials.h"
#endif

// Gère uniquement le cycle de démarrage — rien d'autre.
// Appelé en boucle depuis taskBoot jusqu'à ce que l'état soit OPERATIONAL.
//
//   PROVISIONING ──► CONNECTING ──► OPERATIONAL
//        ▲                │ (échec)
//        └── WIFI_FAILED ◄┘  (efface config, retour provisioning)
//
// NE crée PAS de tâches. NE surveille PAS le WiFi après le boot.
class BootManager {
public:
    BootManager(WifiManager& wifi, ConfigManager& cfg, Scale& scale, ApiClient*& api)
        : _wifi(wifi), _cfg(cfg), _scale(scale), _api(api) {}

    // Appelé une fois dans setup(), après que les queues/semaphores sont initialisés.
    // En simulation avec credentials.h : pré-remplit les credentials pour éviter la saisie manuelle.
    void begin() {
#if defined(NO_BLE) && defined(SIM_SSID) && defined(SIM_TOKEN)
        snprintf(gCredsJson, sizeof(gCredsJson),
            "{\"ssid\":\"%s\",\"password\":\"%s\","
            "\"token\":\"%s\",\"api_url\":\"%s\",\"user_id\":%d}",
            SIM_SSID, SIM_PASSWORD, SIM_TOKEN, SIM_API_URL, SIM_USER_ID);
        xSemaphoreGive(credsSem);
        Serial.println("[Boot] Auto-provisioning depuis credentials.h");
#endif
    }

    // Machine à états du boot — retourne immédiatement si rien à faire.
    // Une fois OPERATIONAL, ne fait plus rien (appels suivants retournent en une microseconde).
    void loop() {
        if (gState.state() == BalanceState::OPERATIONAL) return;

        // ── PROVISIONING : attend les credentials ────────────────────────────
        if (!_cfg.isProvisioned()) {
            gState.update([](BalanceStatus& s) { s.state = BalanceState::PROVISIONING; });

            if (xSemaphoreTake(credsSem, 0) != pdTRUE) return;  // pas encore reçu, on reviendra

            if (!_cfg.applyJson(gCredsJson, _scale.getCalibrationFactor())) {
                Serial.println("[Boot] Credentials invalides");
                return;
            }
        }

        // ── CONNECTING : connexion WiFi ──────────────────────────────────────
        const Config& cfg = _cfg.get();
        gState.update([&cfg](BalanceStatus& s) {
            s.state = BalanceState::CONNECTING;
            s.ssid  = cfg.ssid;
        });
        Serial.printf("[Boot] Connexion a %s...\n", cfg.ssid.c_str());

        if (!_wifi.connect(cfg.ssid, cfg.password)) {
            Serial.println("[Boot] WiFi echoue → reset config");
            gState.update([](BalanceStatus& s) { s.state = BalanceState::WIFI_FAILED; });
            _cfg.clear();
            vTaskDelay(pdMS_TO_TICKS(DELAY_WIFI_FAILED_MS));  // pause avant de retourner en provisioning
            return;
        }

        // ── OPERATIONAL ──────────────────────────────────────────────────────
        _api = new ApiClient(cfg.apiUrl, cfg.token, cfg.userId);
        _api->checkHealth();

        gState.update([](BalanceStatus& s) {
            s.state  = BalanceState::OPERATIONAL;
            s.wifiOk = true;
        });
        Serial.println("[Boot] Mode operationnel");
    }

private:
    WifiManager&   _wifi;
    ConfigManager& _cfg;
    Scale&         _scale;
    ApiClient*&    _api;
};
