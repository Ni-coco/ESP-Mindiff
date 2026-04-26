#pragma once

namespace WeightUtils {

inline float gramsToKg(float grams) {
    return grams / 1000.0f;
}

// raw: raw HX711 reading with scale=1, knownGrams: known mass in grams
inline float computeCalibrationFactor(long raw, float knownGrams) {
    if (knownGrams == 0.0f) return 0.0f;
    return (float)raw / knownGrams;
}

// increase=true → displayed weight too low → reduce factor (scale reads too high)
// increase=false → displayed weight too high → raise factor
inline void adjustCalibrationFactor(float& factor, bool increase) {
    if (increase) factor *= 0.95f;
    else          factor *= 1.05f;
}

}
