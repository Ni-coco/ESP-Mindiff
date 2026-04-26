#pragma once
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include "GlobalState.h"

class Display {
public:
    Display(GlobalState& state);

    void begin();
    void render();

private:
    void _renderWaiting();
    void _renderConnecting();
    void _renderOperational();
    void _renderCalibrating();
    void _renderTokenInvalid();

    Adafruit_SSD1306 _oled;
    GlobalState&     _state;
};
