#include "ApiClient.h"
#include <HTTPClient.h>
#include <ArduinoJson.h>

ApiClient::ApiClient(GlobalState& state, ConfigManager& config)
    : _state(state), _config(config) {}

void ApiClient::loop() {
    if (_state.getPhase() != AppPhase::OPERATIONAL) return;

    // ── Health check : bloque l envoi tant que l API n est pas joignable ──
    if (!_state.isApiReachable()) {
        unsigned long now = millis();
        if (now - _lastHealthCheck >= HEALTH_INTERVAL_MS) {
            _lastHealthCheck = now;
            _checkHealth();
        }
        return;  // pas d envoi avant que l API reponde
    }

    // ── Envoi du poids stable ─────────────────────────────────────────────
    float kg = _state.takePendingWeight();
    if (kg < 0.0f) return;  // rien a envoyer

    if (!_sendWeight(kg)) {
        // Erreur → on re-marque l API comme non joignable pour recheck
        _state.setApiReachable(false);
        _state.setPendingWeight(kg);  // on remet le poids pour reessayer
    }
}

// Retire le suffixe "/api" pour obtenir la base URL
// ex: "https://apidev.nini.network/api" → "https://apidev.nini.network"
String ApiClient::_baseUrl() {
    String url = _config.getApiUrl();
    if (url.endsWith("/api")) {
        url = url.substring(0, url.length() - 4);
    }
    return url;
}

void ApiClient::_checkHealth() {
    String url = _baseUrl() + "/health";

    HTTPClient http;
    http.begin(url);
    http.setTimeout(5000);  // 5s max pour le health check

    Serial.println("[API] GET " + url);
    int code = http.GET();
    http.end();

    if (code == 200) {
        _state.setApiReachable(true);
        Serial.println("[API] Health OK → envoi active");
    } else {
        _state.setApiReachable(false);
        Serial.println("[API] Health KO (code " + String(code) + ") → retry dans 10s");
    }
}

bool ApiClient::_sendWeight(float kg) {
    String token  = _config.getToken();
    String apiUrl = _config.getApiUrl();
    int    userId = _config.getUserId();

    if (apiUrl.length() < 10 || token.length() == 0) {
        Serial.println("[API] Credentials manquants, envoi annule");
        return true;  // pas la peine de reessayer sans credentials
    }

    // Route : POST /user/{user_id}/weight
    String url = apiUrl + "/user/" + String(userId) + "/weight";

    HTTPClient http;
    http.begin(url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("Authorization", "Bearer " + token);

    StaticJsonDocument<128> body;
    body["weight"] = kg;
    body["source"] = "balance";  // source reconnue par le back
    String bodyStr;
    serializeJson(body, bodyStr);

    Serial.println("[API] POST " + url + " → " + bodyStr);

    int code = http.POST(bodyStr);

    if (code > 0) {
        Serial.println("[API] Reponse " + String(code) + " : " + http.getString());
        http.end();
        return (code >= 200 && code < 300);
    } else {
        Serial.println("[API] Erreur HTTP : " + http.errorToString(code));
        http.end();
        return false;
    }
}
