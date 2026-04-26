#include <unity.h>
#include "ConfigManager.h"

static ConfigManager config;

void setUp() {
    config = ConfigManager{};
}

void tearDown() {}

void test_defaults_without_load() {
    TEST_ASSERT_EQUAL_STRING("Balance-ESP32", config.getName().c_str());
    TEST_ASSERT_EQUAL_STRING("", config.getWifiSsid().c_str());
    TEST_ASSERT_EQUAL_STRING("", config.getWifiPassword().c_str());
    TEST_ASSERT_EQUAL_STRING("", config.getToken().c_str());
    TEST_ASSERT_EQUAL_STRING("", config.getApiUrl().c_str());
    TEST_ASSERT_EQUAL(0, config.getUserId());
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 420.0f, config.getCalibFactor());
    TEST_ASSERT_EQUAL(0L, config.getTareOffset());
}

void test_save_then_load_restores_values() {
    config.setName("BalanceCuisine");
    config.setWifiCredentials("Maison", "secret");
    config.setApiCredentials("tok-1", "http://api.local/api", 42);
    config.setCalibFactor(123.45f);
    config.setTareOffset(9876L);
    config.save();

    config.setName("tmp");
    config.setWifiCredentials("tmp", "tmp");
    config.setApiCredentials("tmp", "tmp", 0);
    config.setCalibFactor(1.0f);
    config.setTareOffset(1L);

    config.load();

    TEST_ASSERT_EQUAL_STRING("BalanceCuisine", config.getName().c_str());
    TEST_ASSERT_EQUAL_STRING("Maison", config.getWifiSsid().c_str());
    TEST_ASSERT_EQUAL_STRING("secret", config.getWifiPassword().c_str());
    TEST_ASSERT_EQUAL_STRING("tok-1", config.getToken().c_str());
    TEST_ASSERT_EQUAL_STRING("http://api.local/api", config.getApiUrl().c_str());
    TEST_ASSERT_EQUAL(42, config.getUserId());
    TEST_ASSERT_FLOAT_WITHIN(0.01f, 123.45f, config.getCalibFactor());
    TEST_ASSERT_EQUAL(9876L, config.getTareOffset());
}

void test_clear_then_load_keeps_current_defaults() {
    config.setName("X");
    config.setWifiCredentials("S", "P");
    config.setApiCredentials("T", "U", 7);
    config.setCalibFactor(99.0f);
    config.setTareOffset(55L);
    config.save();

    config.clear();

    config.setName("Balance-ESP32");
    config.setWifiCredentials("", "");
    config.setApiCredentials("", "", 0);
    config.setCalibFactor(420.0f);
    config.setTareOffset(0L);
    config.load();

    TEST_ASSERT_EQUAL_STRING("Balance-ESP32", config.getName().c_str());
    TEST_ASSERT_EQUAL_STRING("", config.getWifiSsid().c_str());
    TEST_ASSERT_EQUAL_STRING("", config.getWifiPassword().c_str());
    TEST_ASSERT_EQUAL_STRING("", config.getToken().c_str());
    TEST_ASSERT_EQUAL_STRING("", config.getApiUrl().c_str());
    TEST_ASSERT_EQUAL(0, config.getUserId());
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 420.0f, config.getCalibFactor());
    TEST_ASSERT_EQUAL(0L, config.getTareOffset());
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_defaults_without_load);
    RUN_TEST(test_save_then_load_restores_values);
    RUN_TEST(test_clear_then_load_keeps_current_defaults);
    return UNITY_END();
}
