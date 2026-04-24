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

void Display::render(const BalanceStatus& status) {
    _oled.clearDisplay();
    switch (status.state) {
        case BalanceState::PROVISIONING: _renderProvisioning(status); break;
        case BalanceState::CONNECTING:   _renderConnecting(status);   break;
        case BalanceState::OPERATIONAL:  _renderOperational(status);  break;
    }
    _oled.display();
}

// ─── Layouts par état ─────────────────────────────────────────────────────────

void Display::_renderProvisioning(const BalanceStatus& s) {
    _drawHeader("== CONFIG ==");

    _oled.setTextSize(1);

    _oled.setCursor(0, 14);
    _oled.println("Envoie le JSON via");
    _oled.println("Serial ou BLE :");

    _oled.setCursor(0, 36);
    _oled.print("[");
    _oled.print(s.serialReady ? "X" : " ");
    _oled.println("] Serial pret");

    _oled.print("[");
    _oled.print(s.bleReady ? "X" : " ");
    _oled.println("] BLE pret");
}

void Display::_renderConnecting(const BalanceStatus& s) {
    _drawHeader("== WIFI ==");

    _oled.setTextSize(1);
    _oled.setCursor(0, 18);
    _oled.print("Connexion a : ");
    _oled.println(s.ssid.length() > 0 ? s.ssid : "...");

    _oled.setCursor(0, 36);
    _oled.println("En cours...");

    _drawFooter("Patience");
}

void Display::_renderOperational(const BalanceStatus& s) {
    // Poids en grand
    _oled.setTextSize(2);
    _oled.setCursor(0, 0);
    _oled.print(s.weightKg, 3);
    _oled.println(" kg");

    // Facteur de calibration
    _oled.setTextSize(1);
    _oled.setCursor(0, 18);
    _oled.print("Cal: ");
    _oled.println(s.calibFactor, 1);

    // Statut WiFi + API
    _oled.setCursor(0, 30);
    _oled.print("WiFi:");
    _oled.print(s.wifiOk ? "OK " : "ERR");
    _oled.print("  API:");
    _oled.println(s.apiOk ? "OK" : "ERR");

    // Aide calibration
    _oled.setCursor(0, 42);
    _oled.println("t:tare c:cal +:+ -:-");

    // Dernier événement
    _drawFooter(s.lastEvent);
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

void Display::_drawHeader(const char* title) {
    _oled.setTextSize(1);
    _oled.setCursor(0, 0);
    _oled.println(title);
    // Ligne de séparation
    _oled.drawLine(0, 9, SCREEN_WIDTH, 9, SSD1306_WHITE);
}

void Display::_drawFooter(const String& msg) {
    // Ligne de séparation en bas
    _oled.drawLine(0, 54, SCREEN_WIDTH, 54, SSD1306_WHITE);
    _oled.setTextSize(1);
    _oled.setCursor(0, 56);
    _oled.print(msg.substring(0, 21)); // max 21 chars à size 1
}

// ─── Calibration (overlay temporaire) ────────────────────────────────────────

void Display::showTareDone() {
    _oled.fillRect(20, 18, 88, 12, SSD1306_BLACK);
    _oled.setTextSize(1);
    _oled.setCursor(24, 20);
    _oled.println("Tare: done");
    _oled.display();
}

void Display::showCalibrationPrompt() {
    _oled.fillRect(0, 36, SCREEN_WIDTH, 28, SSD1306_BLACK);
    _oled.setTextSize(1);
    _oled.setCursor(0, 36);
    _oled.println("Calibrate:");
    _oled.println("Tare OK, pose poids");
    _oled.println("Entrez kg < 15s");
    _oled.display();
}

void Display::showCalibrationInput(const String& buf) {
    _oled.fillRect(0, 52, SCREEN_WIDTH, 12, SSD1306_BLACK);
    _oled.setCursor(0, 52);
    _oled.print(buf);
    _oled.display();
}

void Display::showCalibrationResult(float factor) {
    _oled.fillRect(0, 36, SCREEN_WIDTH, 28, SSD1306_BLACK);
    _oled.setCursor(0, 36);
    _oled.println("Calibration done");
    _oled.print("Cal: ");
    _oled.println(factor, 1);
    _oled.display();
}

void Display::showCalibrationInvalid() {
    _oled.fillRect(0, 36, SCREEN_WIDTH, 28, SSD1306_BLACK);
    _oled.setCursor(0, 36);
    _oled.println("Invalid weight");
    _oled.display();
}

void Display::showCalibrationTimeout() {
    _oled.fillRect(0, 36, SCREEN_WIDTH, 28, SSD1306_BLACK);
    _oled.setCursor(0, 36);
    _oled.println("Calibration timeout");
    _oled.display();
}
