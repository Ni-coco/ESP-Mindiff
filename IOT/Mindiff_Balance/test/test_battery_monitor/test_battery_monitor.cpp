#include <unity.h>
#include "Arduino.h"
#include "GlobalState.h"
#include "BatteryMonitor.h"

static GlobalState state;
static BatteryMonitor* monitor;

void setUp() {
    state = GlobalState{};
    state.init();
    monitor = new BatteryMonitor(35, state);
}

void tearDown() {
    delete monitor;
}

void test_battery_percent_low_clamped_to_zero() {
    setAnalogMilliVolts(1000);
    monitor->loop();
    TEST_ASSERT_EQUAL(0, state.getBattery());
}

void test_battery_percent_mid_range() {
    setAnalogMilliVolts(1800);
    monitor->loop();
    TEST_ASSERT_EQUAL(50, state.getBattery());
}

void test_battery_percent_high_clamped_to_hundred() {
    setAnalogMilliVolts(2500);
    monitor->loop();
    TEST_ASSERT_EQUAL(100, state.getBattery());
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_battery_percent_low_clamped_to_zero);
    RUN_TEST(test_battery_percent_mid_range);
    RUN_TEST(test_battery_percent_high_clamped_to_hundred);
    return UNITY_END();
}
