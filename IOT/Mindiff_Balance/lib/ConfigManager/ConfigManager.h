#pragma once
#include <Arduino.h>
#include <ArduinoJson.h>

// ─── Toutes les données persistées en NVS ────────────────────────────────────
struct Config {
    // Credentials WiFi + API
    String ssid;
    String password;
    String token;
    String apiUrl;
    int    userId      = -1;

    // Scale
    float  calibFactor = 1000.0f;
};

// ─── Accès unique à la persistance (NVS) ─────────────────────────────────────
class ConfigManager {
public:
    // Charge depuis NVS → retourne true si des credentials valides existent
    bool load();

    // Sauvegarde la config complète en NVS
    void save(const Config& config);

    // Parse un JSON de provisioning et sauvegarde si valide.
    // Retourne false si le JSON est invalide ou incomplet.
    // Format : {"ssid":"...","password":"...","token":"...","api_url":"...","user_id":1}
    bool applyJson(const char* json, float currentCalibFactor = 1000.0f);

    // Efface tout en NVS (ex : credentials WiFi invalides)
    void clear();

    // True si ssid + token sont renseignés
    bool isProvisioned() const;

    const Config& get() const;

private:
    Config _config;
};
