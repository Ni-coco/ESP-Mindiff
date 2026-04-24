#pragma once
#include <Arduino.h>
#include <functional>

// ─── UUIDs ───────────────────────────────────────────────────────────────────
#define BLE_SERVICE_UUID     "12345678-1234-1234-1234-123456789abc"
// App → ESP32 : JSON credentials  (WRITE)
#define BLE_PROVISION_UUID   "abcd1234-ab12-cd34-ef56-abcdef123456"
// ESP32 → App : status feedback   (NOTIFY)
#define BLE_STATUS_UUID      "dcba4321-dc43-ba21-fe98-fedcba654321"

// ─────────────────────────────────────────────────────────────────────────────
// NO_BLE : défini dans [env:wokwi] → stub silencieux, aucun header BLE inclus
//          (Wokwi ne simule pas le hardware Bluetooth → panic au boot sinon)
// ─────────────────────────────────────────────────────────────────────────────
#ifdef NO_BLE

class BleManager {
public:
    using ProvisionCallback = std::function<void(const String& jsonPayload)>;
    void beginProvisioning(const char*, ProvisionCallback) {}
    void notifyStatus(const String&) {}
    void stopProvisioning() {}
    bool isClientConnected() const { return false; }
};

#else  // hardware réel ────────────────────────────────────────────────────────

#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

class BleManager {
public:
    using ProvisionCallback = std::function<void(const String& jsonPayload)>;

    void beginProvisioning(const char* deviceName, ProvisionCallback onProvision);
    void notifyStatus(const String& status);
    void stopProvisioning();
    bool isClientConnected() const;

private:
    BLEServer*         _server         = nullptr;
    BLECharacteristic* _provisionChar  = nullptr;
    BLECharacteristic* _statusChar     = nullptr;
    bool               _connected      = false;
    ProvisionCallback  _onProvision;

    friend class BleServerCallbacks;
    friend class BleWriteCallbacks;
};

#endif // NO_BLE
