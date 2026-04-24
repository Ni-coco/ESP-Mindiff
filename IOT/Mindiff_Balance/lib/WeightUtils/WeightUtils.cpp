#include "WeightUtils.h"

namespace WeightUtils {

float gramsToKg(float grams) {
    return grams / 1000.0f;
}

float computeCalibrationFactor(long rawReading, float knownGrams) {
    if (knownGrams <= 0.0f) return 0.0f;
    return (float)rawReading / knownGrams;
}

void adjustCalibrationFactor(float& factor, bool increase) {
    if (increase) {
        factor *= 0.95f;
    } else {
        factor *= 1.05f;
    }
}

}
