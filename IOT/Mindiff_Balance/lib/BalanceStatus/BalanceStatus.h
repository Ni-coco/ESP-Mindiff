#pragma once
#include <Arduino.h>

enum class BalanceState {
    PROVISIONING,   // En attente de credentials (Serial ou BLE)
    CONNECTING,     // Connexion WiFi en cours
    OPERATIONAL,    // Mesure + envoi API
};

struct BalanceStatus {
    BalanceState state       = BalanceState::PROVISIONING;

    // PROVISIONING
    bool         serialReady = true;
    bool         bleReady    = false;

    // CONNECTING
    String       ssid        = "";

    // OPERATIONAL
    float        weightKg    = 0.0f;
    float        calibFactor = 1000.0f;
    bool         wifiOk      = false;
    bool         apiOk       = false;
    String       lastEvent   = "";   // ex: "POST OK", "WiFi perdu"
};
