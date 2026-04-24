#pragma once
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "BalanceStatus.h"

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

class Display {
public:
    Display();
    bool begin();

    // Rendu principal — appelle cette méthode à chaque changement d'état
    void render(const BalanceStatus& status);

    // Méthodes utilitaires pour les messages de calibration (OPERATIONAL)
    void showTareDone();
    void showCalibrationPrompt();
    void showCalibrationInput(const String& buf);
    void showCalibrationResult(float factor);
    void showCalibrationInvalid();
    void showCalibrationTimeout();

private:
    Adafruit_SSD1306 _oled;

    void _renderProvisioning(const BalanceStatus& s);
    void _renderConnecting(const BalanceStatus& s);
    void _renderOperational(const BalanceStatus& s);

    void _drawHeader(const char* title);
    void _drawFooter(const String& msg);
};
