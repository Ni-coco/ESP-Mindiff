#include <unity.h>
#include "GlobalState.h"

static GlobalState state;

void setUp() {
    state = GlobalState{};
    state.init();
}

void tearDown() {}

// ── Phase ─────────────────────────────────────────────────────────────────────

void test_default_phase_is_waiting_credentials() {
    TEST_ASSERT_EQUAL(AppPhase::WAITING_CREDENTIALS, state.getPhase());
}

void test_phase_transitions() {
    state.setPhase(AppPhase::CONNECTING);
    TEST_ASSERT_EQUAL(AppPhase::CONNECTING, state.getPhase());

    state.setPhase(AppPhase::OPERATIONAL);
    TEST_ASSERT_EQUAL(AppPhase::OPERATIONAL, state.getPhase());

    state.setPhase(AppPhase::CALIBRATING);
    TEST_ASSERT_EQUAL(AppPhase::CALIBRATING, state.getPhase());

    state.setPhase(AppPhase::WAITING_CREDENTIALS);
    TEST_ASSERT_EQUAL(AppPhase::WAITING_CREDENTIALS, state.getPhase());
}

// ── Weight ────────────────────────────────────────────────────────────────────

void test_weight_get_set() {
    state.setWeight(72.5f);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 72.5f, state.getWeight());
}

// ── Battery ───────────────────────────────────────────────────────────────────

void test_battery_get_set() {
    state.setBattery(85);
    TEST_ASSERT_EQUAL(85, state.getBattery());
}

// ── Connected ─────────────────────────────────────────────────────────────────

void test_connected_get_set() {
    TEST_ASSERT_FALSE(state.isConnected());
    state.setConnected(true);
    TEST_ASSERT_TRUE(state.isConnected());
    state.setConnected(false);
    TEST_ASSERT_FALSE(state.isConnected());
}

// ── Pending weight (atomic read + clear) ──────────────────────────────────────

void test_pending_weight_initially_negative() {
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -1.0f, state.takePendingWeight());
}

void test_take_pending_weight_returns_value_then_minus_one() {
    state.setPendingWeight(80.0f);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 80.0f, state.takePendingWeight());
    // second take returns sentinel
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -1.0f, state.takePendingWeight());
}

void test_clear_pending_weight() {
    state.setPendingWeight(65.0f);
    state.clearPendingWeight();
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -1.0f, state.takePendingWeight());
}

// ── API check ─────────────────────────────────────────────────────────────────

void test_api_check_initially_true() {
    // Default initializer sets _apiCheckNeeded = true (boot health check)
    TEST_ASSERT_TRUE(state.takeApiCheckNeeded());
}

void test_take_api_check_needed_clears_flag() {
    state.takeApiCheckNeeded();  // consume initial true
    TEST_ASSERT_FALSE(state.takeApiCheckNeeded());
}

void test_request_api_check_sets_flag_and_resets_reachable() {
    state.takeApiCheckNeeded();       // drain initial
    state.setApiReachable(true);
    state.setTokenInvalid(true);

    state.requestApiCheck();

    TEST_ASSERT_TRUE(state.takeApiCheckNeeded());
    TEST_ASSERT_FALSE(state.isApiReachable());
    TEST_ASSERT_FALSE(state.isTokenInvalid());
}

// ── Token invalid ─────────────────────────────────────────────────────────────

void test_token_invalid_get_set() {
    TEST_ASSERT_FALSE(state.isTokenInvalid());
    state.setTokenInvalid(true);
    TEST_ASSERT_TRUE(state.isTokenInvalid());
    state.setTokenInvalid(false);
    TEST_ASSERT_FALSE(state.isTokenInvalid());
}

// ── Pending BLE response (atomic read + clear) ────────────────────────────────

void test_pending_response_initially_empty() {
    TEST_ASSERT_EQUAL_STRING("", state.takePendingResponse().c_str());
}

void test_take_pending_response_clears() {
    state.setPendingResponse("{\"type\":\"status\",\"synced\":true}");
    TEST_ASSERT_EQUAL_STRING(
        "{\"type\":\"status\",\"synced\":true}",
        state.takePendingResponse().c_str()
    );
    // second take is empty
    TEST_ASSERT_EQUAL_STRING("", state.takePendingResponse().c_str());
}

// ── Calibration pending ───────────────────────────────────────────────────────

void test_calib_pending_initially_zero() {
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.0f, state.takeCalibPending());
}

void test_calib_pending_set_and_take() {
    state.setCalibPending(2.5f);
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 2.5f, state.takeCalibPending());
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.0f, state.takeCalibPending());
}

// ── Calibration done ──────────────────────────────────────────────────────────

void test_calib_done_lifecycle() {
    TEST_ASSERT_FALSE(state.isCalibDone());

    state.setCalibDone(true, 5.0f);

    TEST_ASSERT_TRUE(state.isCalibDone());
    TEST_ASSERT_TRUE(state.isCalibOk());
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 5.0f, state.getCalibKgUsed());

    state.clearCalibDone();
    TEST_ASSERT_FALSE(state.isCalibDone());
}

void test_calib_done_failure() {
    state.setCalibDone(false, 3.0f);
    TEST_ASSERT_TRUE(state.isCalibDone());
    TEST_ASSERT_FALSE(state.isCalibOk());
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 3.0f, state.getCalibKgUsed());
}

// ── WiFi credentials ──────────────────────────────────────────────────────────

void test_wifi_credentials() {
    state.setWifiCredentials("HomeNet", "secret123");
    TEST_ASSERT_EQUAL_STRING("HomeNet",   state.getWifiSsid().c_str());
    TEST_ASSERT_EQUAL_STRING("secret123", state.getWifiPassword().c_str());
}

void test_wifi_credentials_initially_empty() {
    TEST_ASSERT_EQUAL_STRING("", state.getWifiSsid().c_str());
    TEST_ASSERT_EQUAL_STRING("", state.getWifiPassword().c_str());
}

// ── Name ──────────────────────────────────────────────────────────────────────

void test_name_default() {
    TEST_ASSERT_EQUAL_STRING("Balance-ESP32", state.getName().c_str());
}

void test_name_set() {
    state.setName("MaBalance");
    TEST_ASSERT_EQUAL_STRING("MaBalance", state.getName().c_str());
}

// ── Runner ────────────────────────────────────────────────────────────────────

int main(int, char**) {
    UNITY_BEGIN();

    RUN_TEST(test_default_phase_is_waiting_credentials);
    RUN_TEST(test_phase_transitions);
    RUN_TEST(test_weight_get_set);
    RUN_TEST(test_battery_get_set);
    RUN_TEST(test_connected_get_set);
    RUN_TEST(test_pending_weight_initially_negative);
    RUN_TEST(test_take_pending_weight_returns_value_then_minus_one);
    RUN_TEST(test_clear_pending_weight);
    RUN_TEST(test_api_check_initially_true);
    RUN_TEST(test_take_api_check_needed_clears_flag);
    RUN_TEST(test_request_api_check_sets_flag_and_resets_reachable);
    RUN_TEST(test_token_invalid_get_set);
    RUN_TEST(test_pending_response_initially_empty);
    RUN_TEST(test_take_pending_response_clears);
    RUN_TEST(test_calib_pending_initially_zero);
    RUN_TEST(test_calib_pending_set_and_take);
    RUN_TEST(test_calib_done_lifecycle);
    RUN_TEST(test_calib_done_failure);
    RUN_TEST(test_wifi_credentials);
    RUN_TEST(test_wifi_credentials_initially_empty);
    RUN_TEST(test_name_default);
    RUN_TEST(test_name_set);

    return UNITY_END();
}
