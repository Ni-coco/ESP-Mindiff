#pragma once
#include <Arduino.h>
#include <functional>

// ─── UUIDs ───────────────────────────────────────────────────────────────────
#define BLE_SERVICE_UUID    "12345678-1234-1234-1234-123456789abc"
// App → ESP32 : JSON credentials WiFi   (WRITE)
#define BLE_PROVISION_UUID  "abcd1234-ab12-cd34-ef56-abcdef123456"
// ESP32 → App : feedback provisioning   (NOTIFY)
#define BLE_STATUS_UUID     "dcba4321-dc43-ba21-fe98-fedcba654321"
// App → ESP32 : commandes calibration   (WRITE) {"cmd":"tare"} etc.
#define BLE_CMD_UUID        "abcd5678-ab56-cd78-ef90-abcdef567890"
// ESP32 → App : poids live              (NOTIFY) {"weight":1.234,...}
#define BLE_WEIGHT_UUID     "dcba8765-dc87-ba65-fe32-fedcba987654"

// ─────────────────────────────────────────────────────────────────────────────
// NO_BLE : défini dans [env:wokwi] → stub silencieux, aucun header BLE inclus
//          (Wokwi ne simule pas le hardware Bluetooth → panic au boot sinon)
// ─────────────────────────────────────────────────────────────────────────────
#ifdef NO_BLE

class BleManager {
public:
    using ProvisionCallback = std::function<void(const String&)>;
    using CalibCallback     = std::function<void(const String&)>;
    void begin(const char*, ProvisionCallback, CalibCallback) {}
    void notifyStatus(const String&) {}
    void notifyWeight(const String&) {}
    bool isClientConnected() const { return false; }
};

#else  // hardware réel ────────────────────────────────────────────────────────

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

class BleManager {
public:
    using ProvisionCallback = std::function<void(const String&)>;
    using CalibCallback     = std::function<void(const String&)>;

    // Démarre BLE avec toutes les characteristics.
    // onProvision : appelé quand l'app envoie des credentials WiFi
    // onCalib     : appelé quand l'app envoie une commande JSON de calibration
    void begin(const char* deviceName, ProvisionCallback onProvision, CalibCallback onCalib);

    // Notifie l'app du statut de provisioning
    void notifyStatus(const String& status);

    // Notifie l'app du poids et état courants (JSON)
    void notifyWeight(const String& json);

    bool isClientConnected() const;

private:
    BLEServer*         _server        = nullptr;
    BLECharacteristic* _provisionChar = nullptr;
    BLECharacteristic* _statusChar    = nullptr;
    BLECharacteristic* _cmdChar       = nullptr;
    BLECharacteristic* _weightChar    = nullptr;
    bool               _connected     = false;
    ProvisionCallback  _onProvision;
    CalibCallback      _onCalib;

    friend class BleServerCallbacks;
    friend class BleProvisionCallbacks;
    friend class BleCmdCallbacks;
};

#endif // NO_BLE
