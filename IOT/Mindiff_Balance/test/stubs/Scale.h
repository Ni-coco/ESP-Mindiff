#pragma once
#include "GlobalState.h"
#include "ConfigManager.h"

// Minimal stub — shadows lib/Scale/Scale.h for native test builds.
// Tracks tare() calls via a global counter the test can inspect.
extern int scale_tare_count;

class Scale {
public:
    Scale(int, int, GlobalState&, ConfigManager&) {}
    void begin(float = 420.0f) {}
    void tare()  { scale_tare_count++; }
    void loop()  {}
};
