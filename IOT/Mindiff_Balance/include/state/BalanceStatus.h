#pragma once
#include <Arduino.h>

enum class BalanceState {
    PROVISIONING,  // En attente credentials (BLE ou Serial)
    CONNECTING,    // Connexion WiFi en cours
    WIFI_FAILED,   // WiFi échoué → retour provisioning dans 2s
    OPERATIONAL,   // Tout opérationnel
};

struct BalanceStatus {
    BalanceState state = BalanceState::PROVISIONING;

    // Connectivité
    String ssid         = "";
    bool   wifiOk       = false;
    bool   apiOk        = false;
    bool   bleReady     = false;
    bool   bleConnected = false;

    // Poids
    float  weightKg    = 0.0f;
    float  calibFactor = 1000.0f;

    // UI
    String lastEvent = "";
};
