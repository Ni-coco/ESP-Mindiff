#pragma once
#include <Arduino.h>
#include "GlobalState.h"
#include "ConfigManager.h"

class ApiClient {
public:
    ApiClient(GlobalState& state, ConfigManager& config);

    void loop();  // verifie s il y a un poids en attente et l envoie

private:
    bool    _sendWeight(float kg);
    void    _checkHealth();          // GET /health, met a jour _state.setApiReachable()
    String  _baseUrl();              // extrait la base URL depuis apiUrl (enleve /api)

    GlobalState&   _state;
    ConfigManager& _config;

    unsigned long _lastHealthCheck = 0;
    static constexpr unsigned long HEALTH_INTERVAL_MS = 10000;  // retry toutes les 10s
};
