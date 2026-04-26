#pragma once
#include <Arduino.h>
#include <Preferences.h>

class ConfigManager {
public:
    void load();
    void save();
    void clear();

    // Nom
    String getName()                       const { return _name;         }
    void   setName(const String& name)           { _name = name;         }

    // WiFi
    String getWifiSsid()                   const { return _wifiSsid;     }
    String getWifiPassword()               const { return _wifiPassword; }
    void   setWifiCredentials(const String& ssid, const String& password) {
        _wifiSsid = ssid; _wifiPassword = password;
    }

    // API
    String getToken()                      const { return _token;        }
    String getApiUrl()                     const { return _apiUrl;       }
    int    getUserId()                     const { return _userId;       }
    void   setApiCredentials(const String& token, const String& apiUrl, int userId) {
        _token = token; _apiUrl = apiUrl; _userId = userId;
    }

    // Calibration HX711
    float  getCalibFactor()                const { return _calibFactor;  }
    void   setCalibFactor(float factor)          { _calibFactor = factor;}

private:
    Preferences _prefs;

    String _name         = "Balance-ESP32";
    String _wifiSsid     = "";
    String _wifiPassword = "";
    String _token        = "";
    String _apiUrl       = "";
    int    _userId       = 0;
    float  _calibFactor  = 420.0f;
};
