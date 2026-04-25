#pragma once
#include <Arduino.h>
#include <ArduinoJson.h>

// Protocole de calibration — même JSON quel que soit le transport (BLE ou Serial)
//   {"cmd":"tare"}
//   {"cmd":"calibrate","kg":1.0}
//   {"cmd":"adjust","dir":"+"}  ou  "-"

enum class CalibCmd { TARE, CALIBRATE, ADJUST_UP, ADJUST_DOWN };

struct CalibCommand {
    CalibCmd type;
    float    knownKg = 0.0f;
};

inline bool parseCalibCommand(const String& json, CalibCommand& out) {
    StaticJsonDocument<128> doc;
    if (deserializeJson(doc, json) != DeserializationError::Ok) return false;

    const char* cmd = doc["cmd"] | "";

    if (strcmp(cmd, "tare") == 0) {
        out.type = CalibCmd::TARE;
        return true;
    }
    if (strcmp(cmd, "calibrate") == 0) {
        float kg = doc["kg"] | 0.0f;
        if (kg <= 0.0f) return false;
        out.type = CalibCmd::CALIBRATE; out.knownKg = kg;
        return true;
    }
    if (strcmp(cmd, "adjust") == 0) {
        const char* dir = doc["dir"] | "";
        if (strcmp(dir, "+") == 0) { out.type = CalibCmd::ADJUST_UP;   return true; }
        if (strcmp(dir, "-") == 0) { out.type = CalibCmd::ADJUST_DOWN; return true; }
    }
    return false;
}
