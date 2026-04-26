#include <unity.h>

// Scale stub definition (declared extern in test/stubs/Scale.h)
int scale_tare_count = 0;

#include "GlobalState.h"
#include "ConfigManager.h"
#include "Scale.h"
#include "CommandHandler.h"

static GlobalState*    state;
static ConfigManager*  config;
static Scale*          scale;
static CommandHandler* handler;

void setUp() {
    scale_tare_count = 0;

    state  = new GlobalState();
    state->init();

    config  = new ConfigManager();
    scale   = new Scale(0, 0, *state, *config);
    handler = new CommandHandler(*scale, *state, *config);
}

void tearDown() {
    delete handler;
    delete scale;
    delete config;
    delete state;
}

// ── Robustness ────────────────────────────────────────────────────────────────

void test_invalid_json_does_not_crash() {
    handler->handle("not json at all");
    TEST_PASS();
}

void test_empty_json_does_not_crash() {
    handler->handle("{}");
    TEST_PASS();
}

void test_unknown_command_does_not_crash() {
    handler->handle("{\"cmd\":\"foobar\"}");
    TEST_PASS();
}

// ── tare ─────────────────────────────────────────────────────────────────────

void test_tare_calls_scale_tare() {
    handler->handle("{\"cmd\":\"tare\"}");
    TEST_ASSERT_EQUAL(1, scale_tare_count);
}

// ── rename ────────────────────────────────────────────────────────────────────

void test_rename_updates_config_and_state() {
    handler->handle("{\"cmd\":\"rename\",\"name\":\"MaBalance\"}");
    TEST_ASSERT_EQUAL_STRING("MaBalance", config->getName().c_str());
    TEST_ASSERT_EQUAL_STRING("MaBalance", state->getName().c_str());
}

void test_rename_missing_name_field_no_change() {
    config->setName("Original");
    handler->handle("{\"cmd\":\"rename\"}");
    TEST_ASSERT_EQUAL_STRING("Original", config->getName().c_str());
}

// ── wifi ──────────────────────────────────────────────────────────────────────

void test_wifi_sets_credentials_and_phase() {
    handler->handle("{\"cmd\":\"wifi\",\"ssid\":\"HomeNet\",\"password\":\"pass123\"}");
    TEST_ASSERT_EQUAL_STRING("HomeNet",  config->getWifiSsid().c_str());
    TEST_ASSERT_EQUAL_STRING("pass123", config->getWifiPassword().c_str());
    TEST_ASSERT_EQUAL_STRING("HomeNet",  state->getWifiSsid().c_str());
    TEST_ASSERT_EQUAL(AppPhase::CONNECTING, state->getPhase());
}

void test_wifi_missing_ssid_field_no_change() {
    handler->handle("{\"cmd\":\"wifi\",\"password\":\"pass\"}");
    TEST_ASSERT_EQUAL_STRING("", config->getWifiSsid().c_str());
    TEST_ASSERT_EQUAL(AppPhase::WAITING_CREDENTIALS, state->getPhase());
}

void test_wifi_with_token_saves_api_credentials() {
    handler->handle(
        "{\"cmd\":\"wifi\","
        "\"ssid\":\"Net\",\"password\":\"pw\","
        "\"token\":\"tok123\","
        "\"api_url\":\"http://api:8082/api\","
        "\"user_id\":42}"
    );
    TEST_ASSERT_EQUAL_STRING("tok123",            config->getToken().c_str());
    TEST_ASSERT_EQUAL_STRING("http://api:8082/api", config->getApiUrl().c_str());
    TEST_ASSERT_EQUAL(42, config->getUserId());
}

void test_wifi_without_token_leaves_api_creds_unchanged() {
    config->setApiCredentials("existing-token", "http://old", 7);
    handler->handle("{\"cmd\":\"wifi\",\"ssid\":\"Net\",\"password\":\"pw\"}");
    TEST_ASSERT_EQUAL_STRING("existing-token", config->getToken().c_str());
}

// ── api ───────────────────────────────────────────────────────────────────────

void test_api_cmd_updates_credentials_and_requests_check() {
    state->takeApiCheckNeeded();  // drain initial boot flag
    handler->handle(
        "{\"cmd\":\"api\","
        "\"token\":\"newtoken\","
        "\"api_url\":\"http://new:8082/api\","
        "\"user_id\":99}"
    );
    TEST_ASSERT_EQUAL_STRING("newtoken",           config->getToken().c_str());
    TEST_ASSERT_EQUAL_STRING("http://new:8082/api", config->getApiUrl().c_str());
    TEST_ASSERT_EQUAL(99, config->getUserId());
    TEST_ASSERT_TRUE(state->takeApiCheckNeeded());
}

void test_api_cmd_missing_fields_no_change() {
    config->setApiCredentials("original", "http://orig", 1);
    handler->handle("{\"cmd\":\"api\",\"token\":\"t\"}");  // missing api_url
    TEST_ASSERT_EQUAL_STRING("original", config->getToken().c_str());
}

// ── status ────────────────────────────────────────────────────────────────────

void test_status_no_credentials_responds_synced_false() {
    handler->handle("{\"cmd\":\"status\"}");
    String resp = state->takePendingResponse();
    TEST_ASSERT_EQUAL_STRING("{\"type\":\"status\",\"synced\":false}", resp.c_str());
}

void test_status_with_credentials_responds_synced_true() {
    config->setWifiCredentials("HomeNet", "pw");
    handler->handle("{\"cmd\":\"status\"}");
    String resp = state->takePendingResponse();
    TEST_ASSERT_EQUAL_STRING("{\"type\":\"status\",\"synced\":true}", resp.c_str());
}

void test_status_response_is_consumed_after_take() {
    handler->handle("{\"cmd\":\"status\"}");
    state->takePendingResponse();  // consume
    TEST_ASSERT_EQUAL_STRING("", state->takePendingResponse().c_str());
}

// ── calib ─────────────────────────────────────────────────────────────────────

void test_calib_valid_weight_sets_calibrating_phase() {
    handler->handle("{\"cmd\":\"calib\",\"weight\":2.5}");
    TEST_ASSERT_EQUAL(AppPhase::CALIBRATING, state->getPhase());
}

void test_calib_valid_weight_sets_calib_pending() {
    handler->handle("{\"cmd\":\"calib\",\"weight\":2.5}");
    float pending = state->takeCalibPending();
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 2.5f, pending);
}

void test_calib_zero_weight_no_phase_change() {
    handler->handle("{\"cmd\":\"calib\",\"weight\":0}");
    TEST_ASSERT_EQUAL(AppPhase::WAITING_CREDENTIALS, state->getPhase());
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.0f, state->takeCalibPending());
}

void test_calib_missing_weight_field_no_phase_change() {
    handler->handle("{\"cmd\":\"calib\"}");
    TEST_ASSERT_EQUAL(AppPhase::WAITING_CREDENTIALS, state->getPhase());
}

// ── restart / reset (stubbed ESP.restart) ─────────────────────────────────────

void test_restart_does_not_crash() {
    handler->handle("{\"cmd\":\"restart\"}");
    TEST_PASS();
}

void test_reset_does_not_crash() {
    handler->handle("{\"cmd\":\"reset\"}");
    TEST_PASS();
}

// ── Runner ────────────────────────────────────────────────────────────────────

int main(int, char**) {
    UNITY_BEGIN();

    RUN_TEST(test_invalid_json_does_not_crash);
    RUN_TEST(test_empty_json_does_not_crash);
    RUN_TEST(test_unknown_command_does_not_crash);

    RUN_TEST(test_tare_calls_scale_tare);

    RUN_TEST(test_rename_updates_config_and_state);
    RUN_TEST(test_rename_missing_name_field_no_change);

    RUN_TEST(test_wifi_sets_credentials_and_phase);
    RUN_TEST(test_wifi_missing_ssid_field_no_change);
    RUN_TEST(test_wifi_with_token_saves_api_credentials);
    RUN_TEST(test_wifi_without_token_leaves_api_creds_unchanged);

    RUN_TEST(test_api_cmd_updates_credentials_and_requests_check);
    RUN_TEST(test_api_cmd_missing_fields_no_change);

    RUN_TEST(test_status_no_credentials_responds_synced_false);
    RUN_TEST(test_status_with_credentials_responds_synced_true);
    RUN_TEST(test_status_response_is_consumed_after_take);

    RUN_TEST(test_calib_valid_weight_sets_calibrating_phase);
    RUN_TEST(test_calib_valid_weight_sets_calib_pending);
    RUN_TEST(test_calib_zero_weight_no_phase_change);
    RUN_TEST(test_calib_missing_weight_field_no_phase_change);

    RUN_TEST(test_restart_does_not_crash);
    RUN_TEST(test_reset_does_not_crash);

    return UNITY_END();
}
