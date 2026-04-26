#pragma once
#include <Arduino.h>
#include <map>
#include <string>
#include <cstdio>

// In-memory stub for ESP32 NVS Preferences.
// Each instance holds its own key→value map (string-encoded).
class Preferences {
    std::map<std::string, std::string> _data;
public:
    void begin(const char*, bool = false) {}
    void end() {}
    void clear() { _data.clear(); }

    String getString(const char* key, String def = "") const {
        auto it = _data.find(key);
        return it != _data.end() ? String(it->second.c_str()) : def;
    }
    bool putString(const char* key, const String& val) {
        _data[key] = val.c_str(); return true;
    }

    int getInt(const char* key, int def = 0) const {
        auto it = _data.find(key);
        return it != _data.end() ? std::stoi(it->second) : def;
    }
    bool putInt(const char* key, int val) {
        _data[key] = std::to_string(val); return true;
    }

    float getFloat(const char* key, float def = 0.0f) const {
        auto it = _data.find(key);
        return it != _data.end() ? std::stof(it->second) : def;
    }
    bool putFloat(const char* key, float val) {
        char buf[32]; std::snprintf(buf, sizeof(buf), "%f", val);
        _data[key] = buf; return true;
    }

    long getLong(const char* key, long def = 0) const {
        auto it = _data.find(key);
        return it != _data.end() ? std::stol(it->second) : def;
    }
    bool putLong(const char* key, long val) {
        _data[key] = std::to_string(val); return true;
    }
};
