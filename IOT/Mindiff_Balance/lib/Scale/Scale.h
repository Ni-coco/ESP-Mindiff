#pragma once
#include <HX711.h>
#include "GlobalState.h"
#include <Arduino.h>

class Scale {
public:
    Scale(int pinDout, int pinSck, GlobalState& state);

    void  begin(float calibFactor = 420.0f);
    void  tare();   // remet le zero
    void  loop();   // lit le poids et met a jour le GlobalState

private:
    float _read();          // lecture brute en kg
    void  _checkStability(float kg);  // detecte le poids stable

    HX711        _hx711;
    int          _pinDout;
    int          _pinSck;
    float        _lastKg    = 0.0f;
    GlobalState& _state;

    // Detection de stabilite
    static constexpr int   STABLE_SAMPLES   = 15;    // 15 × 200ms = 3s
    static constexpr float STABLE_THRESHOLD = 0.1f;  // variation max en kg
    static constexpr float MIN_WEIGHT       = 1.0f;  // poids min pour detecter

    float _samples[STABLE_SAMPLES] = {};
    int   _sampleIdx   = 0;
    int   _sampleCount = 0;
    bool  _wasStable   = false;  // evite d envoyer plusieurs fois le meme poids
};
