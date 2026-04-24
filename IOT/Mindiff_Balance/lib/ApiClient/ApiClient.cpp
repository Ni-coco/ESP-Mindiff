#include "ApiClient.h"
#include <HTTPClient.h>
#include <ArduinoJson.h>

ApiClient::ApiClient(const String& baseUrl, const String& token, int userId)
    : _baseUrl(baseUrl), _token(token), _userId(userId) {}

bool ApiClient::postWeight(float weightKg) {
    if (_baseUrl.isEmpty() || _token.isEmpty() || _userId < 0) return false;

    HTTPClient http;
    String url = _baseUrl + "/user/" + String(_userId) + "/weight";
    http.begin(url);
    http.addHeader("Content-Type",  "application/json");
    http.addHeader("Authorization", "Bearer " + _token);

    StaticJsonDocument<128> doc;
    doc["weight"] = weightKg;
    doc["source"] = "scale";

    String body;
    serializeJson(doc, body);

    int code = http.POST(body);
    http.end();

    return code >= 200 && code < 300;
}
