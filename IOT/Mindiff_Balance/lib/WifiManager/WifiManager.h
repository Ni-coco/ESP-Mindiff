#pragma once
#include <Arduino.h>
#include <WiFi.h>
#include "GlobalState.h"
#include "ConfigManager.h"

#define WIFI_TIMEOUT_MS   10000  // 10s avant de reessayer
#define WIFI_MAX_ATTEMPTS     3  // tentatives max avant retour WAITING_CREDENTIALS

class WifiManager {
public:
    WifiManager(GlobalState& state, ConfigManager& config);

    void begin();
    void loop();

private:
    void _tryConnect();      // phase CONNECTING : tente / retente la connexion
    void _checkConnection(); // phase OPERATIONAL : surveille la connexion

    GlobalState&   _state;
    ConfigManager& _config;

    bool          _connecting   = false;
    unsigned long _lastAttempt  = 0;
    int           _attempts     = 0;
};
