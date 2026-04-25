#include "WifiManager.h"
#include <WiFi.h>

bool WifiManager::connect(const String& ssid, const String& pass, uint32_t timeoutMs) {
    WiFi.begin(ssid.c_str(), pass.c_str());
    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - start < timeoutMs) {
        delay(500);
    }
    return WiFi.status() == WL_CONNECTED;
}

bool WifiManager::reconnect(uint32_t timeoutMs) {
    WiFi.reconnect();
    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - start < timeoutMs) {
        delay(500);
    }
    return WiFi.status() == WL_CONNECTED;
}

bool WifiManager::isConnected() const {
    return WiFi.status() == WL_CONNECTED;
}

bool WifiManager::loop() {
    if (isConnected()) return true;
    Serial.println("[WiFi] Connexion perdue, reconnexion...");
    bool ok = reconnect(5000);
    Serial.println(ok ? "[WiFi] Reconnecte" : "[WiFi] Echec reconnexion");
    return ok;
}
