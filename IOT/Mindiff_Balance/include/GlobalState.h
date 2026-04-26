#pragma once
#include <Arduino.h>
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>

enum class AppPhase {
    WAITING_CREDENTIALS,  // Pas de credentials → attente BLE/Serial
    CONNECTING,           // Credentials recus → connexion WiFi (futur)
    OPERATIONAL           // Tout operationnel → mesure + envoi
};

// Donnees partagees entre les tasks. Acces protege par mutex.
class GlobalState {
public:
    void init() { _mutex = xSemaphoreCreateMutex(); }

    // ── Phase de l application ─────────────────────────────────────────────
    void     setPhase(AppPhase p) { lock(); _phase = p;  unlock(); }
    AppPhase getPhase()           { lock(); AppPhase v = _phase; unlock(); return v; }

    // ── Poids ──────────────────────────────────────────────────────────────
    void  setWeight(float kg) { lock(); _weightKg   = kg;  unlock(); }
    float getWeight()         { lock(); float v = _weightKg;  unlock(); return v; }

    // ── Batterie ───────────────────────────────────────────────────────────
    void setBattery(int pct)  { lock(); _batteryPct = pct; unlock(); }
    int  getBattery()         { lock(); int v = _batteryPct; unlock(); return v; }

    // ── Connexion comm ─────────────────────────────────────────────────────
    void setConnected(bool c) { lock(); _connected  = c;   unlock(); }
    bool isConnected()        { lock(); bool v = _connected; unlock(); return v; }

    // ── WiFi ───────────────────────────────────────────────────────────────
    void setWifiAttempts(int n)    { lock(); _wifiAttempts = n;    unlock(); }
    int  getWifiAttempts()         { lock(); int v = _wifiAttempts; unlock(); return v; }
    void setWifiError(bool e)      { lock(); _wifiError = e;       unlock(); }
    bool hasWifiError()            { lock(); bool v = _wifiError;  unlock(); return v; }

    // ── Accessibilite API ──────────────────────────────────────────────────
    void setApiReachable(bool r) { lock(); _apiReachable = r; unlock(); }
    bool isApiReachable()        { lock(); bool v = _apiReachable; unlock(); return v; }

    // ── Poids stable en attente d envoi API ────────────────────────────────
    // Scale appelle setPendingWeight quand stable.
    // ApiClient appelle takePendingWeight pour lire ET remettre a -1 atomiquement.
    void  setPendingWeight(float kg) { lock(); _pendingWeight = kg; unlock(); }
    void  clearPendingWeight()       { lock(); _pendingWeight = -1.0f; unlock(); }
    float takePendingWeight() {
        lock();
        float v = _pendingWeight;
        _pendingWeight = -1.0f;
        unlock();
        return v;  // -1 = rien a envoyer
    }

    // ── Nom de la balance ──────────────────────────────────────────────────
    void   setName(const String& name) { lock(); _name = name; unlock(); }
    String getName()                   { lock(); String v = _name; unlock(); return v; }

    // ── Credentials WiFi ───────────────────────────────────────────────────
    void setWifiCredentials(const String& ssid, const String& password) {
        lock(); _wifiSsid = ssid; _wifiPassword = password; unlock();
    }
    String getWifiSsid()     { lock(); String v = _wifiSsid;     unlock(); return v; }
    String getWifiPassword() { lock(); String v = _wifiPassword; unlock(); return v; }

private:
    void lock()   { xSemaphoreTake(_mutex, portMAX_DELAY); }
    void unlock() { xSemaphoreGive(_mutex); }

    AppPhase          _phase        = AppPhase::WAITING_CREDENTIALS;
    float             _weightKg     = 0.0f;
    int               _batteryPct   = 0;
    bool              _connected    = false;
    String            _name         = "Balance-ESP32";
    String            _wifiSsid     = "";
    String            _wifiPassword = "";
    int               _wifiAttempts = 0;
    bool              _wifiError    = false;
    bool              _apiReachable  = false;
    float             _pendingWeight = -1.0f;
    SemaphoreHandle_t _mutex        = nullptr;
};
