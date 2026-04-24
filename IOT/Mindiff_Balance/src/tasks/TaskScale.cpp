#include "TaskScale.h"
#include "../AppState.h"
#include "../GlobalState.h"

static const int   STABILITY_SAMPLES   = 5;      // lectures consécutives analysées
static const float STABILITY_THRESHOLD = 0.050f; // écart max autorisé (kg)
static const float MIN_WEIGHT_KG       = 0.001f; // TODO: remettre à 3.0f après calibration sur vrai hardware

static Scale* _scale = nullptr;

static void run(void*) {
    float history[STABILITY_SAMPLES] = {};
    int   count = 0;
    bool  sent  = false;

    for (;;) {
        // ── Vérification hardware ─────────────────────────────────────────────
        xSemaphoreTake(scaleMutex, portMAX_DELAY);
        bool ready = _scale->isReady();
        xSemaphoreGive(scaleMutex);

        if (!ready) {
            vTaskDelay(pdMS_TO_TICKS(1000));
            continue;
        }

        // ── Lecture ───────────────────────────────────────────────────────────
        xSemaphoreTake(scaleMutex, portMAX_DELAY);
        float kg = _scale->getWeightKg();
        float cf = _scale->getCalibrationFactor();
        xSemaphoreGive(scaleMutex);

        gState.update([kg, cf](BalanceStatus& s) {
            s.weightKg    = kg;
            s.calibFactor = cf;
        });

        // ── Détection de stabilité ────────────────────────────────────────────
        if (kg < MIN_WEIGHT_KG) {
            count = 0;
            sent  = false;
            gState.update([](BalanceStatus& s) { s.lastEvent = "En attente"; });

        } else if (!sent) {
            history[count % STABILITY_SAMPLES] = kg;
            count++;

            if (count >= STABILITY_SAMPLES) {
                float lo = history[0], hi = history[0];
                for (int i = 1; i < STABILITY_SAMPLES; i++) {
                    lo = min(lo, history[i]);
                    hi = max(hi, history[i]);
                }

                if (hi - lo < STABILITY_THRESHOLD) {
                    // Poids stable → signal à TaskApi (un seul POST par pesée)
                    sent = true;
                    xQueueSend(qStableWeight, &kg, 0);
                    gState.update([](BalanceStatus& s) { s.lastEvent = "Stable !"; });
                } else {
                    // Fenêtre glissante : recule d'un cran pour continuer l'analyse
                    count = STABILITY_SAMPLES - 1;
                    gState.update([](BalanceStatus& s) { s.lastEvent = "Stabilisation..."; });
                }
            } else {
                gState.update([](BalanceStatus& s) { s.lastEvent = "Montee..."; });
            }
        }

        vTaskDelay(pdMS_TO_TICKS(300));
    }
}

void startTaskScale(Scale* scale) {
    _scale = scale;
    xTaskCreatePinnedToCore(run, "Scale", 2048, nullptr, 2, nullptr, 1);
}
