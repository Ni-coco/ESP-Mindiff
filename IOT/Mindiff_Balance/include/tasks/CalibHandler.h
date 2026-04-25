#pragma once
#include "Scale.h"
#include "Display.h"
#include "ConfigManager.h"
#include "WeightUtils.h"
#include "state/AppState.h"
#include "state/GlobalState.h"
#include "protocol/CalibCommand.h"
#include "config/AppConfig.h"

class CalibHandler {
public:
    CalibHandler(Scale& scale, Display& display, ConfigManager& cfg)
        : _scale(scale), _display(display), _cfg(cfg) {}

    void loop() {
        CalibCommand cmd;
        if (xQueueReceive(qCalibCmd, &cmd, portMAX_DELAY) != pdTRUE) return;

        switch (cmd.type) {

            case CalibCmd::TARE:
                xSemaphoreTake(scaleMutex,   portMAX_DELAY); _scale.tare(); xSemaphoreGive(scaleMutex);
                xSemaphoreTake(displayMutex, portMAX_DELAY); _display.showTareDone(); xSemaphoreGive(displayMutex);
                Serial.println("[Calib] Tare OK");
                vTaskDelay(pdMS_TO_TICKS(800));
                break;

            case CalibCmd::CALIBRATE: {
                float grams = (cmd.knownKg * 1000.0f) / SIM_WEIGHT_MULTIPLIER;
                xSemaphoreTake(scaleMutex, portMAX_DELAY);
                float factor = _scale.computeCalibration(grams);
                xSemaphoreGive(scaleMutex);
                Config c = _cfg.get(); c.calibFactor = factor; _cfg.save(c);
                gState.update([factor](BalanceStatus& s) { s.calibFactor = factor; });
                xSemaphoreTake(displayMutex, portMAX_DELAY); _display.showCalibrationResult(factor); xSemaphoreGive(displayMutex);
                Serial.printf("[Calib] Facteur: %.4f\n", factor);
                vTaskDelay(pdMS_TO_TICKS(1500));
                break;
            }

            case CalibCmd::ADJUST_UP:
            case CalibCmd::ADJUST_DOWN: {
                xSemaphoreTake(scaleMutex, portMAX_DELAY);
                float f = _scale.getCalibrationFactor();
                WeightUtils::adjustCalibrationFactor(f, cmd.type == CalibCmd::ADJUST_UP);
                _scale.setCalibrationFactor(f);
                xSemaphoreGive(scaleMutex);
                Config c = _cfg.get(); c.calibFactor = f; _cfg.save(c);
                gState.update([f](BalanceStatus& s) { s.calibFactor = f; });
                break;
            }
        }
    }

private:
    Scale&         _scale;
    Display&       _display;
    ConfigManager& _cfg;
};
