#pragma once
#ifndef NO_BLE

#include "IComm.h"
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

#define BLE_SERVICE_UUID   "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define BLE_CHAR_NOTIFY    "beb5483e-36e1-4688-b7f5-ea07361b26a8"  // balance → app
#define BLE_CHAR_WRITE     "6d68efe5-04b6-4a85-abc4-c2670b7bf7fd"  // app → balance

class BleComm : public IComm,
                public BLEServerCallbacks,
                public BLECharacteristicCallbacks {
public:
    BleComm(GlobalState& state, CommandHandler& cmdHandler)
        : IComm(state, cmdHandler) {}

    void   begin(const String& deviceName) override;
    void   send(const String& json)        override;
    String receive()                        override;
    bool   isConnected()                    override;

    void onConnect   (BLEServer*)           override { _connected = true;  }
    void onDisconnect(BLEServer* server)    override { _connected = false; server->startAdvertising(); }
    void onWrite     (BLECharacteristic* c) override { _received = c->getValue().c_str(); }

private:
    BLECharacteristic* _notifyChar = nullptr;
    bool               _connected  = false;
    String             _received   = "";
};

#endif // NO_BLE
