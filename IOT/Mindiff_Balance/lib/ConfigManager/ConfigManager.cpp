#include "ConfigManager.h"
#include <Preferences.h>
#include <ArduinoJson.h>

static const char* NVS_NS      = "balance";
static const char* KEY_SSID    = "ssid";
static const char* KEY_PASS    = "pass";
static const char* KEY_TOKEN   = "token";
static const char* KEY_API_URL = "api_url";
static const char* KEY_USER_ID = "user_id";
static const char* KEY_CALIB   = "calib";

#ifndef DEFAULT_CALIB_FACTOR
#define DEFAULT_CALIB_FACTOR 1000.0f
#endif

bool ConfigManager::load() {
    Preferences prefs;
    prefs.begin(NVS_NS, true); // lecture seule
    _config.ssid        = prefs.getString(KEY_SSID,    "");
    _config.password    = prefs.getString(KEY_PASS,    "");
    _config.token       = prefs.getString(KEY_TOKEN,   "");
    _config.apiUrl      = prefs.getString(KEY_API_URL, "");
    _config.userId      = prefs.getInt   (KEY_USER_ID, -1);
    _config.calibFactor = prefs.getFloat (KEY_CALIB,   DEFAULT_CALIB_FACTOR);
    prefs.end();
    return isProvisioned();
}

void ConfigManager::save(const Config& config) {
    _config = config;
    Preferences prefs;
    prefs.begin(NVS_NS, false);
    prefs.putString(KEY_SSID,    config.ssid);
    prefs.putString(KEY_PASS,    config.password);
    prefs.putString(KEY_TOKEN,   config.token);
    prefs.putString(KEY_API_URL, config.apiUrl);
    prefs.putInt   (KEY_USER_ID, config.userId);
    prefs.putFloat (KEY_CALIB,   config.calibFactor);
    prefs.end();
}

void ConfigManager::clear() {
    Preferences prefs;
    prefs.begin(NVS_NS, false);
    prefs.clear();
    prefs.end();
    _config = Config{};
}

bool ConfigManager::isProvisioned() const {
    return !_config.ssid.isEmpty() && !_config.token.isEmpty();
}

const Config& ConfigManager::get() const {
    return _config;
}

bool ConfigManager::applyJson(const char* json, float currentCalibFactor) {
    StaticJsonDocument<512> doc;
    if (deserializeJson(doc, json) != DeserializationError::Ok) return false;

    String ssid  = doc["ssid"]  | "";
    String token = doc["token"] | "";
    int    uid   = doc["user_id"] | -1;

    if (ssid.isEmpty() || token.isEmpty() || uid < 0) return false;

    Config cfg;
    cfg.ssid        = ssid;
    cfg.password    = doc["password"] | "";
    cfg.token       = token;
    cfg.apiUrl      = doc["api_url"]  | "";
    cfg.userId      = uid;
    cfg.calibFactor = currentCalibFactor;
    save(cfg);

    Serial.printf("[Config] Sauvegarde OK (user %d)\n", uid);
    return true;
}
