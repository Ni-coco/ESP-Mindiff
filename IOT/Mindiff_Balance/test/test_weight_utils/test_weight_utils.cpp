#include <unity.h>
#include "WeightUtils.h"

void setUp()    {}
void tearDown() {}

void test_grams_to_kg_standard() {
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 1.0f, WeightUtils::gramsToKg(1000.0f));
}

void test_grams_to_kg_half() {
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.5f, WeightUtils::gramsToKg(500.0f));
}

void test_grams_to_kg_zero() {
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.0f, WeightUtils::gramsToKg(0.0f));
}

void test_compute_calibration_factor() {
    // raw=5000, known=500g → factor=10.0
    TEST_ASSERT_FLOAT_WITHIN(0.01f, 10.0f, WeightUtils::computeCalibrationFactor(5000, 500.0f));
}

void test_compute_calibration_zero_known() {
    // division by zero guard → returns 0
    TEST_ASSERT_FLOAT_WITHIN(0.001f, 0.0f, WeightUtils::computeCalibrationFactor(5000, 0.0f));
}

void test_adjust_calibration_increase() {
    float factor = 1000.0f;
    WeightUtils::adjustCalibrationFactor(factor, true);
    TEST_ASSERT_FLOAT_WITHIN(0.1f, 950.0f, factor);
}

void test_adjust_calibration_decrease() {
    float factor = 1000.0f;
    WeightUtils::adjustCalibrationFactor(factor, false);
    TEST_ASSERT_FLOAT_WITHIN(0.1f, 1050.0f, factor);
}

int main(int argc, char** argv) {
    UNITY_BEGIN();
    RUN_TEST(test_grams_to_kg_standard);
    RUN_TEST(test_grams_to_kg_half);
    RUN_TEST(test_grams_to_kg_zero);
    RUN_TEST(test_compute_calibration_factor);
    RUN_TEST(test_compute_calibration_zero_known);
    RUN_TEST(test_adjust_calibration_increase);
    RUN_TEST(test_adjust_calibration_decrease);
    return UNITY_END();
}
