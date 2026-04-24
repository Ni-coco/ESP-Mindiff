#include "Scale.h"
#include "WeightUtils.h"

#ifndef SIM_WEIGHT_MULTIPLIER
#define SIM_WEIGHT_MULTIPLIER 1.0f
#endif

Scale::Scale(int dout, int sck) : _dout(dout), _sck(sck), _calibrationFactor(1000.0f) {}

void Scale::begin(float calibrationFactor) {
    _calibrationFactor = calibrationFactor;
    _hx711.begin(_dout, _sck);
    _hx711.set_scale(_calibrationFactor);
    // Timeout court : begin() est appelé tôt dans setup(), on ne bloque pas longtemps.
    // Si le chip n'est pas prêt ici, isReady() le retentera dans la boucle.
    if (_hx711.wait_ready_timeout(500)) {
        _hx711.tare();
    }
}

void Scale::tare() {
    _hx711.tare();
}

float Scale::getWeightKg() {
    float grams = _hx711.get_units(10);
    float kg = WeightUtils::gramsToKg(grams);
    return kg * SIM_WEIGHT_MULTIPLIER;
}

float Scale::computeCalibration(float knownGrams) {
    // Calibre sur la valeur nette (raw - tare), plus fiable qu'une moyenne brute.
    long raw = _hx711.get_value(20);
    if (raw < 0) raw = -raw;
    _calibrationFactor = WeightUtils::computeCalibrationFactor(raw, knownGrams);
    _hx711.set_scale(_calibrationFactor);
    return _calibrationFactor;
}

void Scale::setCalibrationFactor(float factor) {
    _calibrationFactor = factor;
    _hx711.set_scale(_calibrationFactor);
}

float Scale::getCalibrationFactor() const {
    return _calibrationFactor;
}

bool Scale::isReady() {
    // delay_ms=10 : donne au simulateur Wokwi le temps d'avancer entre chaque check.
    // Sans ça, la boucle interne de wait_ready_timeout tourne trop vite et Wokwi
    // ne peut jamais mettre DT à LOW avant le timeout.
    return _hx711.wait_ready_timeout(3000, 10);
}
