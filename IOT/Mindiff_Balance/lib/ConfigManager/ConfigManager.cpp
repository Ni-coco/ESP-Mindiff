#include "ConfigManager.h"

#define NVS_NAMESPACE "config"

void ConfigManager::load() {
    _prefs.begin(NVS_NAMESPACE, true);

    _name         = _prefs.getString("name",     _name);
    _wifiSsid     = _prefs.getString("wifiSsid", _wifiSsid);
    _wifiPassword = _prefs.getString("wifiPass",  _wifiPassword);
    _token        = _prefs.getString("token",    _token);
    _apiUrl       = _prefs.getString("apiUrl",   _apiUrl);
    _userId       = _prefs.getInt   ("userId",   _userId);
    _calibFactor  = _prefs.getFloat ("calib",    _calibFactor);
    _tareOffset   = _prefs.getLong  ("tare",     _tareOffset);

    _prefs.end();
    Serial.println("[Config] Charge — ssid:" + _wifiSsid + " api:" + _apiUrl);
}

void ConfigManager::save() {
    _prefs.begin(NVS_NAMESPACE, false);

    _prefs.putString("name",     _name);
    _prefs.putString("wifiSsid", _wifiSsid);
    _prefs.putString("wifiPass",  _wifiPassword);
    _prefs.putString("token",    _token);
    _prefs.putString("apiUrl",   _apiUrl);
    _prefs.putInt   ("userId",   _userId);
    _prefs.putFloat ("calib",    _calibFactor);
    _prefs.putLong  ("tare",     _tareOffset);

    _prefs.end();
    Serial.println("[Config] Sauvegarde OK");
}

void ConfigManager::clear() {
    _prefs.begin(NVS_NAMESPACE, false);
    _prefs.clear();
    _prefs.end();
    Serial.println("[Config] NVS efface");
}
