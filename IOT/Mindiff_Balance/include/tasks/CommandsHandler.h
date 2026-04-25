#pragma once
#include "state/AppState.h"
#include "state/GlobalState.h"
#include "protocol/CalibCommand.h"
#include "config/AppConfig.h"

// Reçoit TOUTES les commandes entrantes et les route vers la bonne destination :
//   - JSON provisioning  {"ssid":...}   → gCredsJson + credsSem
//   - JSON calibration   {"cmd":...}    → qCalibCmd
//
// En prod  : via BLE (deux characteristics séparées)
// En Wokwi : via Serial (routing automatique selon le contenu JSON)

#ifndef NO_BLE
#include "BleManager.h"

class CommandsHandler {
public:
    void begin(const char* deviceName) {
        _ble.begin(
            deviceName,
            [](const String& json) {                       // characteristic PROVISION → provisioning
                strncpy(gCredsJson, json.c_str(), sizeof(gCredsJson) - 1);
                xSemaphoreGive(credsSem);
            },
            [](const String& json) {                       // characteristic CMD → calibration
                CalibCommand cmd;
                if (parseCalibCommand(json, cmd)) xQueueSend(qCalibCmd, &cmd, 0);
                else Serial.println("[BLE] Commande invalide : " + json);
            }
        );
        gState.update([](BalanceStatus& s) { s.bleReady = true; });
        Serial.println("[BLE] Actif");
    }

    void loop() {
        bool conn = _ble.isClientConnected();
        gState.update([conn](BalanceStatus& s) { s.bleConnected = conn; });

        if (conn && gState.state() == BalanceState::OPERATIONAL) {
            BalanceStatus s = gState.snapshot();
            String json = "{\"weight\":"  + String(s.weightKg,   3)   +
                          ",\"calib\":"   + String(s.calibFactor, 4)   +
                          ",\"wifi\":"    + (s.wifiOk ? "true":"false") +
                          ",\"api\":"     + (s.apiOk  ? "true":"false") + "}";
            _ble.notifyWeight(json);
        }
    }

private:
    BleManager _ble;
};

#else  // ── Wokwi : Serial ────────────────────────────────────────────────────

class CommandsHandler {
public:
    void begin(const char*) {
        Serial.println("[Serial] Protocole JSON :");
        Serial.println("  Provisioning : {\"ssid\":\"...\",\"password\":\"...\",\"token\":\"...\",\"api_url\":\"...\",\"user_id\":1}");
        Serial.println("  Calibration  : {\"cmd\":\"tare\"} / {\"cmd\":\"calibrate\",\"kg\":1.0} / {\"cmd\":\"adjust\",\"dir\":\"+\"}");
    }

    // Lit le Serial et route chaque JSON vers la bonne destination.
    // - Commande calib reconnue  → qCalibCmd
    // - Autre JSON (provisioning) → gCredsJson + credsSem
    void loop() {
        while (Serial.available()) {
            char ch = Serial.read();
            if (ch == '\n') {
                _buf.trim();
                if (_buf.startsWith("{")) {
                    CalibCommand cmd;
                    if (parseCalibCommand(_buf, cmd)) {
                        xQueueSend(qCalibCmd, &cmd, 0);
                    } else {
                        // Pas une commande calib → on considère que c'est du provisioning
                        strncpy(gCredsJson, _buf.c_str(), sizeof(gCredsJson) - 1);
                        xSemaphoreGive(credsSem);
                    }
                }
                _buf = "";
            } else if (ch != '\r') {
                _buf += ch;
            }
        }
    }

private:
    String _buf;
};

#endif
