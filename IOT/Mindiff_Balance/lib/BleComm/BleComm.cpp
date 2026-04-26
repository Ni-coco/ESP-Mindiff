#include "BleComm.h"
#ifndef NO_BLE

void BleComm::begin(const String& deviceName) {
    BLEDevice::setMTU(512);
    BLEDevice::init(deviceName.c_str());

    BLEServer* server = BLEDevice::createServer();
    server->setCallbacks(this);

    BLEService* service = server->createService(BLE_SERVICE_UUID);

    // Characteristic notify : balance → app
    _notifyChar = service->createCharacteristic(
        BLE_CHAR_NOTIFY,
        BLECharacteristic::PROPERTY_NOTIFY
    );
    _notifyChar->addDescriptor(new BLE2902());

    // Characteristic write : app → balance
    BLECharacteristic* writeChar = service->createCharacteristic(
        BLE_CHAR_WRITE,
        BLECharacteristic::PROPERTY_WRITE
    );
    writeChar->setCallbacks(this);

    service->start();
    server->getAdvertising()->start();

    Serial.println("[BLE] Actif : " + deviceName);
}

void BleComm::send(const String& json) {
    if (!_connected || !_notifyChar) return;
    _notifyChar->setValue(json.c_str());
    _notifyChar->notify();
}

String BleComm::receive() {
    String msg = _received;
    _received  = "";
    return msg;
}

bool BleComm::isConnected() {
    return _connected;
}

#endif // NO_BLE
