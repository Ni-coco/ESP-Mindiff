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
    // Token invalide → ecran dedie, peu importe la phase
    if (_state.isTokenInvalid()) {
        _renderTokenInvalid();
        return;
    }

    switch (_state.getPhase()) {
        case AppPhase::WAITING_CREDENTIALS: _renderWaiting();     break;
        case AppPhase::CONNECTING:          _renderConnecting();   break;
        case AppPhase::OPERATIONAL:         _renderOperational();  break;
        case AppPhase::CALIBRATING:         _renderCalibrating();  break;
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

void Display::_renderCalibrating() {
    _oled.clearDisplay();
    _oled.setTextSize(1);

    if (!_state.isCalibDone()) {
        // ── Calibration en cours ───────────────────────────────────────────
        _oled.setCursor(20, 0);
        _oled.println("Calibration...");

        _oled.setCursor(0, 18);
        _oled.println("Ne bougez pas");
        _oled.setCursor(0, 30);
        _oled.println("l'objet de reference");

        _oled.setTextSize(2);
        _oled.setCursor(40, 46);
        _oled.println("...");
    } else if (_state.isCalibOk()) {
        // ── Succes ────────────────────────────────────────────────────────
        _oled.setCursor(30, 4);
        _oled.println("Calibration");

        _oled.setTextSize(2);
        _oled.setCursor(35, 20);
        _oled.println("OK !");

        _oled.setTextSize(1);
        _oled.setCursor(10, 46);
        _oled.printf("Ref: %.2f kg", _state.getCalibKgUsed());
    } else {
        // ── Echec ─────────────────────────────────────────────────────────
        _oled.setCursor(30, 4);
        _oled.println("Calibration");

        _oled.setTextSize(2);
        _oled.setCursor(20, 20);
        _oled.println("ECHEC");

        _oled.setTextSize(1);
        _oled.setCursor(5, 50);
        _oled.println("Reessayez avec tare");
    }

    _oled.display();
}

void Display::_renderTokenInvalid() {
    float kg = _state.getWeight();

    _oled.clearDisplay();

    // ── Message d erreur ──────────────────────────────────────────────────
    _oled.setTextSize(1);
    _oled.setCursor(10, 0);
    _oled.print("Token API expire !");

    // ── Poids en petit (la balance continue de mesurer) ───────────────────
    _oled.setTextSize(2);
    _oled.setCursor(0, 18);
    _oled.printf("%.2f kg", kg);

    // ── Separateur ────────────────────────────────────────────────────────
    _oled.drawFastHLine(0, 38, 128, SSD1306_WHITE);

    // ── Instruction ───────────────────────────────────────────────────────
    _oled.setTextSize(1);
    _oled.setCursor(5, 44);
    _oled.print("Renvoyez via BLE :");
    _oled.setCursor(5, 55);
    _oled.print("cmd:api + token");

    _oled.display();
}

void Display::_renderOperational() {
    float kg    = _state.getWeight();
    int   bat   = _state.getBattery();
    bool  apiOk = _state.isApiReachable();
    bool  ble   = _state.isConnected();

    _oled.clearDisplay();
    _oled.setTextSize(1);

    // ── Barre de statut (ligne du haut) ───────────────────────────────────
    // BLE (gauche)
    _oled.setCursor(0, 0);
    _oled.print(ble ? "BT:OK" : "BT:--");

    // Batterie (centre)
    _oled.setCursor(44, 0);
    _oled.printf("Bat:%d%%", bat);

    // API (droite)
    _oled.setCursor(92, 0);
    _oled.print(apiOk ? "API:OK" : "API:..");

    // ── Poids (grand) ─────────────────────────────────────────────────────
    _oled.setTextSize(3);
    _oled.setCursor(0, 22);
    _oled.printf("%.2f", kg);

    _oled.setTextSize(2);
    _oled.setCursor(90, 30);
    _oled.print("kg");

    _oled.display();
}
