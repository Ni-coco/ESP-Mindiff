#pragma once
#include <Arduino.h>

#define WIFI_STA 1
#define WL_CONNECTED 3
#define WL_DISCONNECTED 6

class IPAddress {
public:
    String toString() const { return String("192.168.1.123"); }
};

class WiFiClass {
public:
    int modeValue = -1;
    bool autoReconnect = true;
    int statusValue = WL_DISCONNECTED;
    String lastSsid = "";
    String lastPass = "";
    bool disconnectErase = false;

    void mode(int m) { modeValue = m; }
    void setAutoReconnect(bool v) { autoReconnect = v; }
    int status() { return statusValue; }

    void begin(const char* ssid, const char* pass) {
        lastSsid = String(ssid ? ssid : "");
        lastPass = String(pass ? pass : "");
    }

    void disconnect(bool eraseap = false) { disconnectErase = eraseap; }
    IPAddress localIP() const { return IPAddress{}; }

    void resetStub() {
        modeValue = -1;
        autoReconnect = true;
        statusValue = WL_DISCONNECTED;
        lastSsid = "";
        lastPass = "";
        disconnectErase = false;
    }
};

// Singleton so all translation units (test + lib source) share one instance.
inline WiFiClass& _wifi_singleton() { static WiFiClass w; return w; }
#define WiFi (_wifi_singleton())
