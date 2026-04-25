#include "Display.h"
#include <Wire.h>

Display::Display() : _oled(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1) {}

bool Display::begin() {
    Wire.begin(21, 22); // SDA=GPIO21, SCL=GPIO22
    if (!_oled.begin(SSD1306_SWITCHCAPVCC, 0x3C)) return false;
    _oled.clearDisplay();
    _oled.setTextColor(SSD1306_WHITE);
    _oled.display();
    return true;
}

// ─── Rendu principal ──────────────────────────────────────────────────────────

void Display::render(const BalanceStatus& s) {
    _oled.clearDisplay();
    switch (s.state) {
        case BalanceState::PROVISIONING: _renderProvisioning(s); break;
        case BalanceState::CONNECTING:   _renderConnecting(s);   break;
        case BalanceState::WIFI_FAILED:  _renderWifiFailed();    break;
        case BalanceState::OPERATIONAL:  _renderOperational(s);  break;
    }
    _oled.display();
}

// ─── PROVISIONING ─────────────────────────────────────────────────────────────
//
//  ┌──────────────────────┐
//  │ ── CONFIG ──         │
//  │─────────────────────│
//  │ En attente...        │
//  │                      │
//  │ BLE: Balance-ESP32   │  ← ou "Serial: pret"
//  └──────────────────────┘

void Display::_renderProvisioning(const BalanceStatus& s) {
    _drawHeader("-- CONFIG --");

    _oled.setTextSize(1);
    _oled.setCursor(0, 16);
    _oled.println("En attente config...");

    _oled.setCursor(0, 34);
#ifdef NO_BLE
    _oled.println("Serial: pret");
    _oled.println("Envoie le JSON");
#else
    if (s.bleConnected) {
        _oled.println("BLE: Connecte");
        _oled.println("Envoie le JSON");
    } else if (s.bleReady) {
        _oled.println("BLE: Balance-ESP32");
        _oled.println("En attente app...");
    } else {
        _oled.println("BLE: demarrage...");
    }
#endif
}

// ─── CONNECTING ───────────────────────────────────────────────────────────────
//
//  ┌──────────────────────┐
//  │ ── WIFI ──           │
//  │─────────────────────│
//  │ Connexion a :        │
//  │ "Wokwi-GUEST"        │
//  │                      │
//  └──────────────────────┘

void Display::_renderConnecting(const BalanceStatus& s) {
    _drawHeader("-- WiFi --");

    _oled.setTextSize(1);
    _oled.setCursor(0, 16);
    _oled.println("Connexion a :");
    _oled.setCursor(0, 28);
    // Troncature à 21 chars max (largeur écran en size 1)
    _oled.println(s.ssid.substring(0, 21));

    _oled.setCursor(0, 46);
    _oled.println("En cours...");
}

// ─── WIFI_FAILED ──────────────────────────────────────────────────────────────
//
//  ┌──────────────────────┐
//  │ ── ERREUR WiFi ──    │
//  │─────────────────────│
//  │ Connexion impossible │
//  │ Verif. credentials   │
//  │ Retour config...     │
//  └──────────────────────┘

void Display::_renderWifiFailed() {
    _drawHeader("-- ERREUR WiFi --");

    _oled.setTextSize(1);
    _oled.setCursor(0, 16);
    _oled.println("Connexion impossible");
    _oled.setCursor(0, 28);
    _oled.println("Verif. credentials");
    _oled.setCursor(0, 40);
    _oled.println("Retour config...");
}

// ─── OPERATIONAL ──────────────────────────────────────────────────────────────
//
//  ┌──────────────────────┐
//  │ 1.234 kg             │  ← size 2, row 0
//  │─────────────────────│  ← divider row 18
//  │ W:OK  A:OK  B:CON    │  ← statuts row 21
//  │ Cal: 0.42            │  ← row 33
//  │─────────────────────│  ← divider row 45
//  │ En attente           │  ← lastEvent row 48
//  └──────────────────────┘

void Display::_renderOperational(const BalanceStatus& s) {
    // Poids en grand
    _oled.setTextSize(2);
    _oled.setCursor(0, 0);
    _oled.print(s.weightKg, 3);
    _oled.println(" kg");

    // Divider
    _oled.drawLine(0, 18, SCREEN_WIDTH, 18, SSD1306_WHITE);

    // Barre de statuts
    _drawStatusBar(s);

    // Facteur de calibration
    _oled.setTextSize(1);
    _oled.setCursor(0, 33);
    _oled.print("Cal: ");
    _oled.println(s.calibFactor, 2);

    // Footer
    _drawFooter(s.lastEvent);
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

void Display::_drawHeader(const char* title) {
    _oled.setTextSize(1);
    _oled.setCursor(0, 0);
    _oled.println(title);
    _oled.drawLine(0, 9, SCREEN_WIDTH, 9, SSD1306_WHITE);
}

void Display::_drawFooter(const String& msg) {
    _oled.drawLine(0, 45, SCREEN_WIDTH, 45, SSD1306_WHITE);
    _oled.setTextSize(1);
    _oled.setCursor(0, 48);
    _oled.print(msg.substring(0, 21));
}

void Display::_drawStatusBar(const BalanceStatus& s) {
    _oled.setTextSize(1);
    _oled.setCursor(0, 21);

    // WiFi
    _oled.print("W:");
    _oled.print(s.wifiOk ? "OK" : "ERR");

    // API
    _oled.print(" A:");
    _oled.print(s.apiOk ? "OK" : "ERR");

    // BLE
    _oled.print(" B:");
#ifdef NO_BLE
    _oled.print("---");
#else
    if      (s.bleConnected) _oled.print("CON");
    else if (s.bleReady)     _oled.print("ADV");
    else                     _oled.print("OFF");
#endif
}

// ─── Overlays calibration ─────────────────────────────────────────────────────

void Display::showTareDone() {
    _oled.fillRect(0, 48, SCREEN_WIDTH, 16, SSD1306_BLACK);
    _oled.setTextSize(1);
    _oled.setCursor(0, 48);
    _oled.println("Tare OK");
    _oled.display();
}

void Display::showCalibrationResult(float factor) {
    _oled.fillRect(0, 48, SCREEN_WIDTH, 16, SSD1306_BLACK);
    _oled.setTextSize(1);
    _oled.setCursor(0, 48);
    _oled.print("Cal OK: ");
    _oled.println(factor, 2);
    _oled.display();
}

void Display::showCalibrationInvalid() {
    _oled.fillRect(0, 48, SCREEN_WIDTH, 16, SSD1306_BLACK);
    _oled.setTextSize(1);
    _oled.setCursor(0, 48);
    _oled.println("Poids invalide");
    _oled.display();
}
