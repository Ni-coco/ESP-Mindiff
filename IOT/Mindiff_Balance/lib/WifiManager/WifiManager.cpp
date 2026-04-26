#include "WifiManager.h"

WifiManager::WifiManager(GlobalState& state, ConfigManager& config)
    : _state(state), _config(config) {}

void WifiManager::begin() {
    WiFi.mode(WIFI_STA);
    WiFi.setAutoReconnect(false);  // on gere la reconnexion nous-memes
}

void WifiManager::loop() {
    switch (_state.getPhase()) {
        case AppPhase::CONNECTING:   _tryConnect();      break;
        case AppPhase::OPERATIONAL:  _checkConnection(); break;
        default: break;  // WAITING_CREDENTIALS : rien a faire
    }
}

void WifiManager::_tryConnect() {
    // Deja connecte ?
    if (WiFi.status() == WL_CONNECTED) {
        _connecting = false;
        _attempts   = 0;
        _state.setWifiAttempts(0);
        _state.setWifiError(false);
        _state.setPhase(AppPhase::OPERATIONAL);
        Serial.println("[WiFi] Connecte : " + WiFi.localIP().toString());
        return;
    }

    unsigned long now = millis();
    bool timeout      = (now - _lastAttempt) > WIFI_TIMEOUT_MS;

    // Lance une tentative si premiere fois ou apres timeout
    if (!_connecting || timeout) {
        // Max tentatives atteint → retour WAITING_CREDENTIALS
        if (_attempts >= WIFI_MAX_ATTEMPTS) {
            _connecting = false;
            _attempts   = 0;
            WiFi.disconnect(true);
            _config.setWifiCredentials("", "");
            _config.save();
            _state.setWifiAttempts(0);
            _state.setWifiError(true);
            _state.setPhase(AppPhase::WAITING_CREDENTIALS);
            Serial.println("[WiFi] Echec apres " + String(WIFI_MAX_ATTEMPTS) +
                           " tentatives → WAITING_CREDENTIALS");
            return;
        }

        String ssid = _config.getWifiSsid();
        String pass = _config.getWifiPassword();

        WiFi.disconnect(true);
        WiFi.begin(ssid.c_str(), pass.c_str());

        _connecting  = true;
        _lastAttempt = now;
        _attempts++;
        _state.setWifiAttempts(_attempts);
        _state.setWifiError(false);
        Serial.println("[WiFi] Tentative " + String(_attempts) + "/" +
                       String(WIFI_MAX_ATTEMPTS) + " → " + ssid);
    }
}

void WifiManager::_checkConnection() {
    if (WiFi.status() != WL_CONNECTED) {
        _connecting = false;
        _attempts   = 0;
        _state.setPhase(AppPhase::CONNECTING);
        Serial.println("[WiFi] Connexion perdue → CONNECTING");
    }
}
