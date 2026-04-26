#include "BatteryMonitor.h"

#define BAT_MIN_V       3.0f
#define BAT_MAX_V       4.2f
#define VOLTAGE_DIVIDER 2.0f   // Reel : pont 100k/100k → Vbat/2

BatteryMonitor::BatteryMonitor(int pin, GlobalState& state)
    : _pin(pin), _state(state) {}

void BatteryMonitor::begin() {}

void BatteryMonitor::loop() {
    _state.setBattery(_readPercent());
}

int BatteryMonitor::_readPercent() {
    // analogReadMilliVolts() retourne 0-3300 mV independamment de la resolution ADC
    int mv = analogReadMilliVolts(_pin);

#ifdef NO_BLE
    // Simulation Wokwi : potentiometre 0-3300mV → 0-100% direct
    return constrain(mv * 100 / 3300, 0, 100);
#else
    // Reel : diviseur resistif (100k/100k), plage LiPo 3.0V-4.2V
    float volt = (mv / 1000.0f) * VOLTAGE_DIVIDER;
    int   pct  = (int)((volt - BAT_MIN_V) / (BAT_MAX_V - BAT_MIN_V) * 100.0f);
    return constrain(pct, 0, 100);
#endif
}
