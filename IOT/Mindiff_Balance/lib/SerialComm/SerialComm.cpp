#include "SerialComm.h"

void SerialComm::begin(const String& deviceName) {
    Serial.println("[Serial] Comm started : " + deviceName);
}

void SerialComm::send(const String& json) {
    Serial.println(json);
}

String SerialComm::receive() {
    while (Serial.available()) {
        char c = Serial.read();

        if (c == '\n' || c == '\r') {
            String msg = _buf;
            _buf = "";
            msg.trim();
            if (msg.length() > 0) {
                Serial.println("[Serial] Recu : " + msg);
                return msg;
            }
        } else {
            _buf += c;
        }
    }
    return "";
}

bool SerialComm::isConnected() {
    return true;  // Serial toujours disponible
}
