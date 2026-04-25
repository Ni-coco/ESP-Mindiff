#pragma once
#include <Arduino.h>

// WifiManager ne gère plus la persistance (c'est ConfigManager).
// Son seul rôle : connecter et reconnecter.
class WifiManager {
public:
    // Connexion initiale avec les credentials fournis
    bool connect(const String& ssid, const String& pass, uint32_t timeoutMs = 10000);

    // Tentative de reconnexion (réutilise les derniers credentials)
    bool reconnect(uint32_t timeoutMs = 5000);

    bool isConnected() const;

    // Appelé périodiquement — reconnecte automatiquement si la connexion est perdue.
    // Retourne true si connecté, false sinon (ou après tentative échouée).
    bool loop();
};
