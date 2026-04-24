#include "TaskCalibration.h"
#include "WeightUtils.h"
#include "../AppState.h"
#include "../GlobalState.h"

static Scale*         _scale   = nullptr;
static Display*       _display = nullptr;
static ConfigManager* _config  = nullptr;

// ─── Helper : sauvegarde le facteur en NVS et met à jour l'état ──────────────
static void saveCalibFactor(float factor) {
    Config cfg = _config->get();
    cfg.calibFactor = factor;
    _config->save(cfg);
    gState.update([factor](BalanceStatus& s) { s.calibFactor = factor; });
}

// ─── Calibration avec poids connu ────────────────────────────────────────────
static void handleCalibrationInput() {
    // Flush le '\n' résiduel de la commande 'c' (Wokwi envoie 'c'+'\n' ensemble)
    vTaskDelay(pdMS_TO_TICKS(50));
    while (Serial.available()) Serial.read();

    xSemaphoreTake(displayMutex, portMAX_DELAY);
    _display->showCalibrationPrompt();
    xSemaphoreGive(displayMutex);

    String buf;
    unsigned long t0 = millis();

    while (millis() - t0 < 15000) {
        while (Serial.available()) {
            char ch = Serial.read();
            if (ch == '\r') continue;
            if (ch == '\n') {
                float knownKg = buf.toFloat();
                float known   = knownKg * 1000.0f; // convertit kg → grammes pour computeCalibration
                if (known > 0.0f) {
                    xSemaphoreTake(scaleMutex, portMAX_DELAY);
                    float newFactor = _scale->computeCalibration(known);
                    xSemaphoreGive(scaleMutex);

                    saveCalibFactor(newFactor);

                    xSemaphoreTake(displayMutex, portMAX_DELAY);
                    _display->showCalibrationResult(newFactor);
                    xSemaphoreGive(displayMutex);
                    vTaskDelay(pdMS_TO_TICKS(1500));
                } else {
                    xSemaphoreTake(displayMutex, portMAX_DELAY);
                    _display->showCalibrationInvalid();
                    xSemaphoreGive(displayMutex);
                    vTaskDelay(pdMS_TO_TICKS(1200));
                }
                return;
            }
            if (isDigit(ch) || ch == '.') {
                buf += ch;
                xSemaphoreTake(displayMutex, portMAX_DELAY);
                _display->showCalibrationInput(buf);
                xSemaphoreGive(displayMutex);
            }
        }
        vTaskDelay(pdMS_TO_TICKS(50));
    }

    xSemaphoreTake(displayMutex, portMAX_DELAY);
    _display->showCalibrationTimeout();
    xSemaphoreGive(displayMutex);
    vTaskDelay(pdMS_TO_TICKS(1000));
}

// ─── Boucle principale ───────────────────────────────────────────────────────
static void run(void*) {
    for (;;) {
        if (!Serial.available()) {
            vTaskDelay(pdMS_TO_TICKS(100));
            continue;
        }

        char c = Serial.read();
        if (c == '\n' || c == '\r') continue; // ignore les fins de ligne

        if (c == 't') {
            xSemaphoreTake(scaleMutex, portMAX_DELAY);
            _scale->tare();
            xSemaphoreGive(scaleMutex);

            xSemaphoreTake(displayMutex, portMAX_DELAY);
            _display->showTareDone();
            xSemaphoreGive(displayMutex);
            vTaskDelay(pdMS_TO_TICKS(800));

        } else if (c == '+' || c == '-') {
            xSemaphoreTake(scaleMutex, portMAX_DELAY);
            float f = _scale->getCalibrationFactor();
            WeightUtils::adjustCalibrationFactor(f, c == '+');
            _scale->setCalibrationFactor(f);
            xSemaphoreGive(scaleMutex);

            saveCalibFactor(f);

        } else if (c == 'c') {
            handleCalibrationInput();
        }
    }
}

void startTaskCalibration(Scale* scale, Display* display, ConfigManager* config) {
    _scale   = scale;
    _display = display;
    _config  = config;
    xTaskCreatePinnedToCore(run, "Calib", 2048, nullptr, 1, nullptr, 1);
}
