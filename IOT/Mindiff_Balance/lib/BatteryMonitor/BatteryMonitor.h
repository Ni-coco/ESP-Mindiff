#pragma once
#include <Arduino.h>
#include "GlobalState.h"

class BatteryMonitor {
public:
    BatteryMonitor(int pin, GlobalState& state);

    void begin();
    void loop();   // lit la tension et met a jour le GlobalState

private:
    int          _readPercent();  // lecture brute 0-100

    int          _pin;
    GlobalState& _state;
};
