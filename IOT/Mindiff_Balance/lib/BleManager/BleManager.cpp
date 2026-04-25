#include "BleManager.h"

#ifndef NO_BLE

// ─── Callbacks ────────────────────────────────────────────────────────────────

class BleServerCallbacks : public BLEServerCallbacks {
public:
    BleServerCallbacks(BleManager* mgr) : _mgr(mgr) {}
    void onConnect(BLEServer*)    override { _mgr->_connected = true;  }
    void onDisconnect(BLEServer*) override {
        _mgr->_connected = false;
        BLEDevice::getAdvertising()->start(); // re-advertise si déconnexion
    }
private:
    BleManager* _mgr;
};

// App → ESP32 : credentials WiFi (provisioning)
class BleProvisionCallbacks : public BLECharacteristicCallbacks {
public:
    BleProvisionCallbacks(BleManager* mgr) : _mgr(mgr) {}
    void onWrite(BLECharacteristic* pChar) override {
        String payload = String(pChar->getValue().c_str());
        if (!payload.isEmpty() && _mgr->_onProvision) {
            _mgr->_onProvision(payload);
        }
    }
private:
    BleManager* _mgr;
};

// App → ESP32 : commandes calibration JSON
class BleCmdCallbacks : public BLECharacteristicCallbacks {
public:
    BleCmdCallbacks(BleManager* mgr) : _mgr(mgr) {}
    void onWrite(BLECharacteristic* pChar) override {
        String payload = String(pChar->getValue().c_str());
        if (!payload.isEmpty() && _mgr->_onCalib) {
            _mgr->_onCalib(payload);
        }
    }
private:
    BleManager* _mgr;
};

// ─── Public ───────────────────────────────────────────────────────────────────

void BleManager::begin(const char* deviceName, ProvisionCallback onProvision, CalibCallback onCalib) {
    _onProvision = onProvision;
    _onCalib     = onCalib;

    BLEDevice::init(deviceName);
    _server = BLEDevice::createServer();
    _server->setCallbacks(new BleServerCallbacks(this));

    // numHandles=32 : on a 4 characteristics, la valeur par défaut (15) ne suffit pas
    BLEService* service = _server->createService(BLEUUID(BLE_SERVICE_UUID), 32);

    // PROVISION : App → ESP32  (credentials WiFi, WRITE)
    _provisionChar = service->createCharacteristic(BLE_PROVISION_UUID,
        BLECharacteristic::PROPERTY_WRITE);
    _provisionChar->setCallbacks(new BleProvisionCallbacks(this));

    // STATUS : ESP32 → App  (feedback provisioning, NOTIFY)
    _statusChar = service->createCharacteristic(BLE_STATUS_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
    _statusChar->addDescriptor(new BLE2902());

    // CMD : App → ESP32  (commandes calibration JSON, WRITE)
    _cmdChar = service->createCharacteristic(BLE_CMD_UUID,
        BLECharacteristic::PROPERTY_WRITE);
    _cmdChar->setCallbacks(new BleCmdCallbacks(this));

    // WEIGHT : ESP32 → App  (poids live JSON, NOTIFY)
    _weightChar = service->createCharacteristic(BLE_WEIGHT_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
    _weightChar->addDescriptor(new BLE2902());

    service->start();

    BLEAdvertising* adv = BLEDevice::getAdvertising();
    adv->addServiceUUID(BLE_SERVICE_UUID);
    adv->start();
}

void BleManager::notifyStatus(const String& status) {
    if (!_statusChar) return;
    _statusChar->setValue(status.c_str());
    _statusChar->notify();
}

void BleManager::notifyWeight(const String& json) {
    if (!_weightChar) return;
    _weightChar->setValue(json.c_str());
    _weightChar->notify();
}

bool BleManager::isClientConnected() const {
    return _connected;
}

#endif // NO_BLE
