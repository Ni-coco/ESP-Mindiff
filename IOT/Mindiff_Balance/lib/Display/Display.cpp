#include "Display.h"

#define SCREEN_WIDTH  128
#define SCREEN_HEIGHT  64
#define OLED_ADDRESS  0x3C

Display::Display(GlobalState& state)
    : _oled(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1), _state(state) {}

void Display::begin() {
    _oled.begin(SSD1306_SWITCHCAPVCC, OLED_ADDRESS);
    _oled.clearDisplay();
    _oled.setTextColor(SSD1306_WHITE);
    _oled.display();
}

void Display::render() {
    switch (_state.getPhase()) {
        case AppPhase::WAITING_CREDENTIALS: _renderWaiting();    break;
        case AppPhase::CONNECTING:          _renderConnecting();  break;
        case AppPhase::OPERATIONAL:         _renderOperational(); break;
    }
}

void Display::_renderWaiting() {
    _oled.clearDisplay();
    _oled.setTextSize(1);

    if (_state.hasWifiError()) {
        _oled.setCursor(15, 0);
        _oled.println("Connexion echouee !");
        _oled.setCursor(10, 14);
        _oled.println("Verifiez le SSID");
        _oled.setCursor(10, 26);
        _oled.println("et le mot de passe");
        _oled.setCursor(5, 50);
        _oled.println("Renvoyez via BLE");
    } else {
        _oled.setCursor(20, 10);
        _oled.println("En attente des");
        _oled.setCursor(20, 24);
        _oled.println("credentials WiFi");
        _oled.setCursor(10, 48);
        _oled.println("Envoyez via BLE");
    }

    _oled.display();
}

void Display::_renderConnecting() {
    int attempts = _state.getWifiAttempts();

    _oled.clearDisplay();
    _oled.setTextSize(1);

    _oled.setCursor(25, 8);
    _oled.println("Connexion WiFi");
    _oled.setCursor(40, 22);
    _oled.println("en cours...");

    _oled.setCursor(20, 46);
    _oled.printf("Tentative %d/3", attempts);

    _oled.display();
}

void Display::_renderOperational() {
    float kg  = _state.getWeight();
    int   bat = _state.getBattery();

    _oled.clearDisplay();

    _oled.setTextSize(1);
    _oled.setCursor(0, 0);
    _oled.println("Poids mesure :");

    _oled.setTextSize(3);
    _oled.setCursor(0, 20);
    _oled.printf("%.2f", kg);

    _oled.setTextSize(2);
    _oled.setCursor(90, 30);
    _oled.println("kg");

    _oled.setTextSize(1);
    _oled.setCursor(90, 0);
    _oled.printf("Bat:%d%%", bat);

    _oled.display();
}
