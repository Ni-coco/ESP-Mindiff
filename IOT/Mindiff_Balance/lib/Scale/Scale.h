#pragma once
#include "HX711.h"

class Scale {
public:
    Scale(int dout, int sck);
    void begin(float calibrationFactor);
    void tare();
    float getWeightKg();
    float computeCalibration(float knownGrams);
    void setCalibrationFactor(float factor);
    float getCalibrationFactor() const;
    bool isReady();

private:
    HX711 _hx711;
    float _calibrationFactor;
    int _dout;
    int _sck;
};
