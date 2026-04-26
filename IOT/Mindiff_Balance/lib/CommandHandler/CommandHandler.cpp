#include "CommandHandler.h"
#include <ArduinoJson.h>

CommandHandler::CommandHandler(Scale& scale, GlobalState& state, ConfigManager& config)
    : _scale(scale), _state(state), _config(config) {}

void CommandHandler::handle(const String& json) {
    StaticJsonDocument<1024> doc;
    if (deserializeJson(doc, json) != DeserializationError::Ok) {
        Serial.println("[CMD] JSON invalide : " + json);
        return;
    }

    const char* cmd = doc["cmd"];
    if (!cmd) return;

    if (strcmp(cmd, "tare") == 0) {
        _scale.tare();
        Serial.println("[CMD] Tare effectuee");

    } else if (strcmp(cmd, "restart") == 0) {
        Serial.println("[CMD] Restart...");
        delay(500);
        ESP.restart();

    } else if (strcmp(cmd, "reset") == 0) {
        Serial.println("[CMD] Reset — effacement config...");
        _config.clear();
        delay(500);
        ESP.restart();

    } else if (strcmp(cmd, "rename") == 0) {
        const char* name = doc["name"];
        if (name) {
            _config.setName(name);
            _config.save();
            _state.setName(name);
            Serial.println("[CMD] Renomme : " + String(name));
        }

    } else if (strcmp(cmd, "wifi") == 0) {
        const char* ssid     = doc["ssid"];
        const char* password = doc["password"];
        const char* token    = doc["token"];
        const char* apiUrl   = doc["api_url"];
        int         userId   = doc["user_id"] | 0;
        if (ssid && password) {
            _config.setWifiCredentials(ssid, password);
            if (token) _config.setApiCredentials(
                token,
                apiUrl ? apiUrl : _config.getApiUrl().c_str(),
                userId
            );
            _config.save();
            _state.setWifiCredentials(ssid, password);
            _state.requestApiCheck();   // health check immediat a la reconnexion
            _state.setPhase(AppPhase::CONNECTING);
            Serial.println("[CMD] Credentials WiFi sauvegardes → CONNECTING");
            if (token) Serial.println("[CMD] Token API sauvegarde");
        }

    } else if (strcmp(cmd, "api") == 0) {
        const char* token  = doc["token"];
        const char* apiUrl = doc["api_url"];
        int         userId = doc["user_id"] | _config.getUserId();
        if (token && apiUrl) {
            _config.setApiCredentials(token, apiUrl, userId);
            _config.save();
            _state.requestApiCheck();   // re-verifie avec les nouveaux credentials
            Serial.println("[CMD] Credentials API mis a jour → health check");
        }

    } else if (strcmp(cmd, "calib") == 0) {
        float knownKg = doc["weight"] | 0.0f;
        if (knownKg > 0.0f) {
            _state.setCalibPending(knownKg);
            _state.setPhase(AppPhase::CALIBRATING);
            Serial.println("[CMD] Calibration lancee avec " + String(knownKg, 2) + " kg");
        } else {
            Serial.println("[CMD] Calib : champ 'weight' manquant ou nul");
        }

    } else {
        Serial.println("[CMD] Commande inconnue : " + String(cmd));
    }
}
