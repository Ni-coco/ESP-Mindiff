#include "Scale.h"

Scale::Scale(int pinDout, int pinSck, GlobalState& state, ConfigManager& config)
    : _pinDout(pinDout), _pinSck(pinSck), _state(state), _config(config) {}

void Scale::begin(float calibFactor) {
    _hx711.begin(_pinDout, _pinSck);
    while (!_hx711.is_ready()) delay(10);
    _hx711.set_scale(calibFactor);
    // Restaure le zero sauvegarde en NVS
    long savedOffset = _config.getTareOffset();
    if (savedOffset != 0) {
        _hx711.set_offset(savedOffset);
        Serial.println("[Scale] Tare restauree : " + String(savedOffset));
    }
}

void Scale::tare() {
    _hx711.tare();
    // Persiste le nouvel offset en NVS
    _config.setTareOffset(_hx711.get_offset());
    _config.save();
    Serial.println("[Scale] Tare sauvegardee : " + String(_hx711.get_offset()));
}

bool Scale::_calibrate(float knownKg) {
    if (knownKg <= 0.0f) return false;

    // Lit la valeur brute (scale = 1 pour avoir le raw pur)
    _hx711.set_scale(1.0f);
    float raw = _hx711.get_units(20);  // moyenne sur 20 lectures (~2s)

    if (raw == 0.0f) {
        Serial.println("[Scale] Calibration impossible : valeur brute nulle");
        _hx711.set_scale(_config.getCalibFactor());
        return false;
    }

    float factor = raw / knownKg;
    _hx711.set_scale(factor);
    _config.setCalibFactor(factor);
    _config.save();

    Serial.println("[Scale] Calibration OK → raw=" + String(raw, 1) +
                   "  poids=" + String(knownKg, 2) + "kg" +
                   "  factor=" + String(factor, 2));
    return true;
}

void Scale::loop() {
    AppPhase phase = _state.getPhase();

    // ── Mode calibration ──────────────────────────────────────────────────
    if (phase == AppPhase::CALIBRATING) {
        // Retour OPERATIONAL apres 3s d affichage du resultat
        if (_calibDoneAt > 0) {
            if (millis() - _calibDoneAt > 3000) {
                _state.clearCalibDone();
                _calibDoneAt = 0;
                _state.setPhase(AppPhase::OPERATIONAL);
            }
            return;
        }

        // Lit le poids de reference demande par CommandHandler
        float knownKg = _state.takeCalibPending();
        if (knownKg > 0.0f) {
            bool ok = _calibrate(knownKg);
            _state.setCalibDone(ok, knownKg);
            _calibDoneAt = millis();
        }
        return;
    }

    // ── Mode normal ───────────────────────────────────────────────────────
    if (phase != AppPhase::OPERATIONAL) return;
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
