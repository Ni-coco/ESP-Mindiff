#pragma once

namespace WeightUtils {
    float gramsToKg(float grams);
    float computeCalibrationFactor(long rawReading, float knownGrams);
    void adjustCalibrationFactor(float& factor, bool increase);
}
