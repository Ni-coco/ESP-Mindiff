#include "BleManager.h"

#ifndef NO_BLE  // tout ce fichier est exclu quand NO_BLE est défini

// ─── Callbacks internes ───────────────────────────────────────────────────────

class BleServerCallbacks : public BLEServerCallbacks {
public:
    BleServerCallbacks(BleManager* mgr) : _mgr(mgr) {}
    void onConnect(BLEServer*)    override { _mgr->_connected = true;  }
    void onDisconnect(BLEServer*) override {
        _mgr->_connected = false;
        BLEDevice::getAdvertising()->start(); // continue d'advertiser si non provisionné
    }
private:
    BleManager* _mgr;
};

class BleWriteCallbacks : public BLECharacteristicCallbacks {
public:
    BleWriteCallbacks(BleManager* mgr) : _mgr(mgr) {}
    void onWrite(BLECharacteristic* pChar) override {
        String payload = String(pChar->getValue().c_str());
        if (!payload.isEmpty() && _mgr->_onProvision) {
            _mgr->_onProvision(payload);
        }
    }
private:
    BleManager* _mgr;
};

// ─── Public ───────────────────────────────────────────────────────────────────

void BleManager::beginProvisioning(const char* deviceName, ProvisionCallback onProvision) {
    _onProvision = onProvision;

    BLEDevice::init(deviceName);
    _server = BLEDevice::createServer();
    _server->setCallbacks(new BleServerCallbacks(this));

    BLEService* service = _server->createService(BLE_SERVICE_UUID);

    // Characteristic WRITE : reçoit le JSON de l'app
    _provisionChar = service->createCharacteristic(
        BLE_PROVISION_UUID,
        BLECharacteristic::PROPERTY_WRITE
    );
    _provisionChar->setCallbacks(new BleWriteCallbacks(this));

    // Characteristic NOTIFY : renvoie un statut à l'app
    _statusChar = service->createCharacteristic(
        BLE_STATUS_UUID,
        BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
    );
    _statusChar->addDescriptor(new BLE2902());

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

void BleManager::stopProvisioning() {
    BLEDevice::getAdvertising()->stop();
    BLEDevice::deinit(true);
    _server        = nullptr;
    _provisionChar = nullptr;
    _statusChar    = nullptr;
    _connected     = false;
}

bool BleManager::isClientConnected() const {
    return _connected;
}

#endif // NO_BLE
