#include "Scale.h"

Scale::Scale(int pinDout, int pinSck, GlobalState& state)
    : _pinDout(pinDout), _pinSck(pinSck), _state(state) {}

void Scale::begin(float calibFactor) {
    _hx711.begin(_pinDout, _pinSck);
    while (!_hx711.is_ready()) delay(10);
    _hx711.set_scale(calibFactor);
}

void Scale::tare() {
    _hx711.tare();
}

void Scale::loop() {
    if (_state.getPhase() != AppPhase::OPERATIONAL) return;
    float kg = _read();
    _state.setWeight(kg);
    _checkStability(kg);
}

float Scale::_read() {
    if (!_hx711.is_ready()) return _lastKg;
    _lastKg = _hx711.get_units(5);
    return _lastKg;
}

void Scale::_checkStability(float kg) {
    // Remplit le buffer circulaire
    _samples[_sampleIdx] = kg;
    _sampleIdx = (_sampleIdx + 1) % STABLE_SAMPLES;
    if (_sampleCount < STABLE_SAMPLES) _sampleCount++;

    // Pas encore assez d echantillons
    if (_sampleCount < STABLE_SAMPLES) return;

    // Poids trop faible → pas de mesure
    if (kg < MIN_WEIGHT) {
        _wasStable = false;
        return;
    }

    // Cherche min/max dans le buffer
    float minKg = _samples[0], maxKg = _samples[0];
    for (int i = 1; i < STABLE_SAMPLES; i++) {
        if (_samples[i] < minKg) minKg = _samples[i];
        if (_samples[i] > maxKg) maxKg = _samples[i];
    }

    bool stable = (maxKg - minKg) < STABLE_THRESHOLD;

    if (stable && !_wasStable) {
        float avg = 0.0f;
        for (int i = 0; i < STABLE_SAMPLES; i++) avg += _samples[i];
        avg /= STABLE_SAMPLES;
        _state.setPendingWeight(avg);
        Serial.println("[Scale] Poids stable : " + String(avg, 2) + " kg → API");
    }

    _wasStable = stable;
}
