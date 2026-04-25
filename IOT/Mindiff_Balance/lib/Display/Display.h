#pragma once
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "BalanceStatus.h"

#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT  64

class Display {
public:
    Display();
    bool begin();

    // Rendu principal — appelé par TaskDisplay toutes les 200ms
    void render(const BalanceStatus& status);

    // Overlays temporaires pour feedback calibration
    void showTareDone();
    void showCalibrationResult(float factor);
    void showCalibrationInvalid();

private:
    Adafruit_SSD1306 _oled;

    void _renderProvisioning(const BalanceStatus& s);
    void _renderConnecting(const BalanceStatus& s);
    void _renderWifiFailed();
    void _renderOperational(const BalanceStatus& s);

    void _drawHeader(const char* title);
    void _drawFooter(const String& msg);
    void _drawStatusBar(const BalanceStatus& s);
};
