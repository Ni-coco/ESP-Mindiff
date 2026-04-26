#include <unity.h>
#include "Arduino.h"
#include "WiFi.h"
#include "GlobalState.h"
#include "ConfigManager.h"
#include "WifiManager.h"

static GlobalState state;
static ConfigManager config;
static WifiManager* wifi;

void setUp() {
    state = GlobalState{};
    state.init();
    config = ConfigManager{};
    config.setWifiCredentials("HomeNet", "pass123");

    WiFi.resetStub();
    setMillis(0);

    wifi = new WifiManager(state, config);
}

void tearDown() {
    delete wifi;
}

void test_begin_configures_station_mode() {
    wifi->begin();
    TEST_ASSERT_EQUAL(WIFI_STA, WiFi.modeValue);
    TEST_ASSERT_FALSE(WiFi.autoReconnect);
}

void test_connecting_when_already_connected_switches_to_operational() {
    state.setPhase(AppPhase::CONNECTING);
    WiFi.statusValue = WL_CONNECTED;

    wifi->loop();

    TEST_ASSERT_EQUAL(AppPhase::OPERATIONAL, state.getPhase());
    TEST_ASSERT_EQUAL(0, state.getWifiAttempts());
    TEST_ASSERT_FALSE(state.hasWifiError());
}

void test_connecting_starts_attempt_with_saved_credentials() {
    state.setPhase(AppPhase::CONNECTING);
    WiFi.statusValue = WL_DISCONNECTED;

    wifi->loop();

    TEST_ASSERT_EQUAL_STRING("HomeNet", WiFi.lastSsid.c_str());
    TEST_ASSERT_EQUAL_STRING("pass123", WiFi.lastPass.c_str());
    TEST_ASSERT_EQUAL(1, state.getWifiAttempts());
    TEST_ASSERT_FALSE(state.hasWifiError());
}

void test_connecting_exhausts_attempts_and_returns_waiting_credentials() {
    state.setPhase(AppPhase::CONNECTING);
    WiFi.statusValue = WL_DISCONNECTED;

    wifi->loop();
    setMillis(WIFI_TIMEOUT_MS + 1);
    wifi->loop();
    setMillis(2 * (WIFI_TIMEOUT_MS + 1));
    wifi->loop();

    setMillis(3 * (WIFI_TIMEOUT_MS + 1));
    wifi->loop();

    TEST_ASSERT_EQUAL(AppPhase::WAITING_CREDENTIALS, state.getPhase());
    TEST_ASSERT_EQUAL(0, state.getWifiAttempts());
    TEST_ASSERT_TRUE(state.hasWifiError());
    TEST_ASSERT_EQUAL_STRING("", config.getWifiSsid().c_str());
    TEST_ASSERT_TRUE(WiFi.disconnectErase);
}

void test_operational_connection_lost_returns_connecting() {
    state.setPhase(AppPhase::OPERATIONAL);
    WiFi.statusValue = WL_DISCONNECTED;

    wifi->loop();

    TEST_ASSERT_EQUAL(AppPhase::CONNECTING, state.getPhase());
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_begin_configures_station_mode);
    RUN_TEST(test_connecting_when_already_connected_switches_to_operational);
    RUN_TEST(test_connecting_starts_attempt_with_saved_credentials);
    RUN_TEST(test_connecting_exhausts_attempts_and_returns_waiting_credentials);
    RUN_TEST(test_operational_connection_lost_returns_connecting);
    return UNITY_END();
}
