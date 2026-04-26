#include <unity.h>
#include "Arduino.h"
#include "HTTPClient.h"
#include "GlobalState.h"
#include "ConfigManager.h"
#include "ApiClient.h"

static GlobalState state;
static ConfigManager config;
static ApiClient* api;

void setUp() {
    state = GlobalState{};
    state.init();
    state.setPhase(AppPhase::OPERATIONAL);

    config = ConfigManager{};
    config.setApiCredentials("token-123", "http://api.local/api", 7);

    HTTPClient::resetStub();
    setMillis(0);

    api = new ApiClient(state, config);
}

void tearDown() {
    delete api;
}

void test_health_check_uses_base_url_and_marks_api_reachable() {
    HTTPClient::setNextGetCode(200);

    api->loop();

    TEST_ASSERT_TRUE(state.isApiReachable());
    TEST_ASSERT_EQUAL_STRING("http://api.local/health", HTTPClient::getLastBeginUrl().c_str());
}

void test_token_invalid_blocks_weight_send() {
    state.setApiReachable(true);
    state.setTokenInvalid(true);
    state.setPendingWeight(3.5f);

    api->loop();

    TEST_ASSERT_FLOAT_WITHIN(0.001f, 3.5f, state.takePendingWeight());
    TEST_ASSERT_EQUAL_STRING("", HTTPClient::getLastPostBody().c_str());
}

void test_send_weight_success_consumes_pending_weight() {
    state.setApiReachable(true);
    state.setTokenInvalid(false);
    state.setPendingWeight(5.5f);
    HTTPClient::setNextPostCode(201);

    api->loop();

    TEST_ASSERT_FLOAT_WITHIN(0.001f, -1.0f, state.takePendingWeight());
    TEST_ASSERT_EQUAL_STRING("application/json", HTTPClient::getLastContentTypeHeader().c_str());
    TEST_ASSERT_EQUAL_STRING("Bearer token-123", HTTPClient::getLastAuthHeader().c_str());
    TEST_ASSERT_TRUE(HTTPClient::getLastBeginUrl().find("/user/7/weight") != std::string::npos);
}

void test_send_weight_http_error_marks_api_unreachable_and_requeues_weight() {
    state.setApiReachable(true);
    state.setTokenInvalid(false);
    state.setPendingWeight(6.2f);
    HTTPClient::setNextPostCode(-1);

    api->loop();

    TEST_ASSERT_FALSE(state.isApiReachable());
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 6.2f, state.takePendingWeight());
}

void test_send_weight_unauthorized_sets_token_invalid_and_drops_weight() {
    state.setApiReachable(true);
    state.setTokenInvalid(false);
    state.setPendingWeight(7.0f);
    HTTPClient::setNextPostCode(401);

    api->loop();

    TEST_ASSERT_TRUE(state.isTokenInvalid());
    TEST_ASSERT_FLOAT_WITHIN(0.001f, -1.0f, state.takePendingWeight());
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_health_check_uses_base_url_and_marks_api_reachable);
    RUN_TEST(test_token_invalid_blocks_weight_send);
    RUN_TEST(test_send_weight_success_consumes_pending_weight);
    RUN_TEST(test_send_weight_http_error_marks_api_unreachable_and_requeues_weight);
    RUN_TEST(test_send_weight_unauthorized_sets_token_invalid_and_drops_weight);
    return UNITY_END();
}
