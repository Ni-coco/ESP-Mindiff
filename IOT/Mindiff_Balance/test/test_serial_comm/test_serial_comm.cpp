#include <unity.h>

int scale_tare_count = 0;

#include "GlobalState.h"
#include "ConfigManager.h"
#include "Scale.h"
#include "CommandHandler.h"
#include "SerialComm.h"
#include "Arduino.h"

static GlobalState* state;
static ConfigManager* config;
static Scale* scale;
static CommandHandler* handler;
static SerialComm* comm;

void setUp() {
    Serial.rx.clear();
    Serial.clearOutput();

    state = new GlobalState();
    state->init();

    config = new ConfigManager();
    scale = new Scale(0, 0, *state, *config);
    handler = new CommandHandler(*scale, *state, *config);
    comm = new SerialComm(*state, *handler);
}

void tearDown() {
    delete comm;
    delete handler;
    delete scale;
    delete config;
    delete state;
}

void test_is_connected_always_true() {
    TEST_ASSERT_TRUE(comm->isConnected());
}

void test_receive_returns_empty_if_no_complete_line() {
    Serial.inject("{\"cmd\":\"status\"");
    TEST_ASSERT_EQUAL_STRING("", comm->receive().c_str());
}

void test_receive_trims_and_returns_on_newline() {
    Serial.inject("  {\"cmd\":\"status\"}  \n");
    TEST_ASSERT_EQUAL_STRING("{\"cmd\":\"status\"}", comm->receive().c_str());
}

void test_receive_ignores_empty_lines() {
    Serial.inject("\n\r\n");
    TEST_ASSERT_EQUAL_STRING("", comm->receive().c_str());
}

int main(int, char**) {
    UNITY_BEGIN();
    RUN_TEST(test_is_connected_always_true);
    RUN_TEST(test_receive_returns_empty_if_no_complete_line);
    RUN_TEST(test_receive_trims_and_returns_on_newline);
    RUN_TEST(test_receive_ignores_empty_lines);
    return UNITY_END();
}
