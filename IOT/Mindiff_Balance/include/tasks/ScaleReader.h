#pragma once
#include "Scale.h"
#include "state/AppState.h"
#include "state/GlobalState.h"
#include "config/AppConfig.h"

// Lit le poids en continu et met à jour le GlobalState.
// Envoie dans qStableWeight uniquement quand OPERATIONAL et poids stable sur SCALE_SAMPLES lectures.
class ScaleReader {
public:
    ScaleReader(Scale& scale) : _scale(scale) {}

    void loop() {
        xSemaphoreTake(scaleMutex, portMAX_DELAY);
        bool ready = _scale.isReady();
        xSemaphoreGive(scaleMutex);

        if (!ready) { vTaskDelay(pdMS_TO_TICKS(1000)); return; }

        xSemaphoreTake(scaleMutex, portMAX_DELAY);
        float kg = _scale.getWeightKg();
        float cf = _scale.getCalibrationFactor();
        xSemaphoreGive(scaleMutex);

        // Le poids est toujours affiché, même avant d'être OPERATIONAL
        gState.update([kg, cf](BalanceStatus& s) {
            s.weightKg = kg; s.calibFactor = cf;
        });

        if (kg < SCALE_MIN_KG) {
            _count = 0; _sent = false;
            gState.update([](BalanceStatus& s) { s.lastEvent = "En attente"; });

        } else if (!_sent) {
            _history[_count % SCALE_SAMPLES] = kg;
            if (++_count >= SCALE_SAMPLES) {
                float lo = _history[0], hi = _history[0];
                for (int i = 1; i < SCALE_SAMPLES; i++) {
                    lo = min(lo, _history[i]);
                    hi = max(hi, _history[i]);
                }
                if (hi - lo < SCALE_THRESHOLD_KG) {
                    _sent = true;
                    // N'envoie à l'API que si on est opérationnel (WiFi + api prêts)
                    if (gState.state() == BalanceState::OPERATIONAL) {
                        xQueueSend(qStableWeight, &kg, 0);
                    }
                    gState.update([](BalanceStatus& s) { s.lastEvent = "Stable !"; });
                } else {
                    _count = SCALE_SAMPLES - 1;
                    gState.update([](BalanceStatus& s) { s.lastEvent = "Stabilisation..."; });
                }
            } else {
                gState.update([](BalanceStatus& s) { s.lastEvent = "Mesure..."; });
            }
        }
    }

private:
    Scale& _scale;
    float  _history[SCALE_SAMPLES] = {};
    int    _count = 0;
    bool   _sent  = false;
};
