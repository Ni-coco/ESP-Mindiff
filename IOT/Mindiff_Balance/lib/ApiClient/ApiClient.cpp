#include "ApiClient.h"
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <ArduinoJson.h>

ApiClient::ApiClient(const String& baseUrl, const String& token, int userId)
    : _baseUrl(baseUrl), _token(token), _userId(userId) {}

bool ApiClient::checkHealth() {
    // Le endpoint /health est une route séparée, sans le préfixe /api
    // ex: _baseUrl = "https://host/api" → health = "https://host/health"
    String url = _baseUrl;
    int apiIdx = url.lastIndexOf("/api");
    if (apiIdx >= 0) url = url.substring(0, apiIdx);
    url += "/health";

    WiFiClientSecure client;
    client.setInsecure();

    HTTPClient http;
    http.begin(client, url);
    int code = http.GET();
    http.end();

    bool ok = (code == 200);
    Serial.printf("[API] Health %s → %d %s\n", url.c_str(), code, ok ? "OK" : "FAIL");
    return ok;
}

bool ApiClient::postWeight(float weightKg) {
    if (_baseUrl.isEmpty() || _token.isEmpty() || _userId < 0) return false;

    String url = _baseUrl + "/user/" + String(_userId) + "/weight";

    // WiFiClientSecure requis pour HTTPS.
    // setInsecure() : pas de vérification du certificat serveur
    // → acceptable pour un usage IoT interne, à remplacer par setCACert() en prod.
    WiFiClientSecure client;
    client.setInsecure();

    HTTPClient http;
    http.begin(client, url);
    http.addHeader("Content-Type",  "application/json");
    http.addHeader("Authorization", "Bearer " + _token);

    StaticJsonDocument<128> doc;
    doc["weight"] = weightKg;
    doc["source"] = "scale";

    String body;
    serializeJson(doc, body);

    int code = http.POST(body);
    Serial.printf("[API] POST %s → %d\n", url.c_str(), code);
    http.end();

    return code >= 200 && code < 300;
}
