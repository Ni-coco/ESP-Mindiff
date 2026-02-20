#include <Wire.h>
#include "HX711.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// HX711
const int LOADCELL_DOUT_PIN = 16;
const int LOADCELL_SCK_PIN = 4;

HX711 scale;

// OLED
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

float calibration_factor = 1000.0;

// BLE UUIDs (uniques pour ton app)
#define SERVICE_UUID        "12345678-1234-1234-1234-123456789abc"
#define CHARACTERISTIC_UUID "abcd1234-ab12-cd34-ef56-abcdef123456"

BLEServer* pServer = nullptr;
BLECharacteristic* pCharacteristic = nullptr;
bool deviceConnected = false;

// Callbacks connexion BLE
class MyServerCallbacks : public BLEServerCallbacks {
  void onConnect(BLEServer* pServer) {
    deviceConnected = true;
    display.fillRect(0, 56, SCREEN_WIDTH, 8, SSD1306_BLACK);
    display.setTextSize(1);
    display.setCursor(0, 56);
    display.println("BLE: Connecte");
    display.display();
  }
  void onDisconnect(BLEServer* pServer) {
    deviceConnected = false;
    pServer->startAdvertising(); // relance l'advertising
    display.fillRect(0, 56, SCREEN_WIDTH, 8, SSD1306_BLACK);
    display.setTextSize(1);
    display.setCursor(0, 56);
    display.println("BLE: Attente...");
    display.display();
  }
};

void printHelp() {
  display.setTextSize(1);
  display.setCursor(0, 40);
  display.println("t:tare c:cal +:+ -:-");
  display.display();
}

void setup() {
  Serial.begin(115200);
  delay(10);

  // Init scale
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(calibration_factor);
  scale.tare();

  // Init display
  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("SSD1306 allocation failed");
  }
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  display.setCursor(0, 0);
  display.println("Balance initialisee");
  display.display();
  delay(500);

  // Init BLE
  BLEDevice::init("Balance-ESP32");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  BLEService* pService = pServer->createService(SERVICE_UUID);
  pCharacteristic = pService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY
  );
  pCharacteristic->addDescriptor(new BLE2902());
  pService->start();

  BLEAdvertising* pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->start();

  display.setCursor(0, 10);
  display.println("BLE: Attente...");
  display.display();
  delay(500);
  printHelp();
}

void loop() {
  if (!scale.is_ready()) {
    Serial.println("HX711 not found.");
    delay(1000);
    return;
  }

  float weight_g = scale.get_units(10);
  float weight_kg = weight_g / 1000.0;

  // Envoie le poids via BLE
  if (deviceConnected) {
    String weightStr = String(weight_kg, 3);
    pCharacteristic->setValue(weightStr.c_str());
    pCharacteristic->notify();
  }

  // Affichage OLED
  display.fillRect(0, 0, SCREEN_WIDTH, 36, SSD1306_BLACK);
  display.setTextSize(2);
  display.setCursor(0, 0);
  display.print(weight_kg, 3);
  display.println(" kg");
  display.setTextSize(1);
  display.setCursor(0, 30);
  display.print("Cal: ");
  display.println(calibration_factor, 1);
  display.display();

  // Commandes Serial
  if (Serial.available()) {
    char c = Serial.read();
    if (c == 't') {
      scale.tare();
      display.fillRect(20, 18, 88, 12, SSD1306_BLACK);
      display.setTextSize(1);
      display.setCursor(24, 20);
      display.println("Tare: done");
      display.display();
      delay(800);
    } else if (c == '+') {
      calibration_factor *= 0.95;
      scale.set_scale(calibration_factor);
    } else if (c == '-') {
      calibration_factor *= 1.05;
      scale.set_scale(calibration_factor);
    } else if (c == 'c') {
      unsigned long start = millis();
      const unsigned long timeout = 15000;
      String buf = "";
      display.fillRect(0, 36, SCREEN_WIDTH, 28, SSD1306_BLACK);
      display.setTextSize(1);
      display.setCursor(0, 36);
      display.println("Calibrate:");
      display.println("Place known weight");
      display.println("Type grams within 15s");
      display.display();
      while (millis() - start < timeout) {
        while (Serial.available()) {
          char ch = Serial.read();
          if (ch == '\r') continue;
          if (ch == '\n') {
            float known = buf.toFloat();
            if (known > 0.0) {
              long raw = scale.read_average(20);
              float newCal = (float)raw / known;
              calibration_factor = newCal;
              scale.set_scale(calibration_factor);
              display.fillRect(0, 36, SCREEN_WIDTH, 28, SSD1306_BLACK);
              display.setCursor(0, 36);
              display.println("Calibration done");
              display.print("Cal: "); display.println(calibration_factor, 1);
              display.display();
              delay(1500);
            } else {
              display.fillRect(0, 36, SCREEN_WIDTH, 28, SSD1306_BLACK);
              display.setCursor(0, 36);
              display.println("Invalid weight");
              display.display();
              delay(1200);
            }
            buf = "";
            goto calib_done;
          } else if (isDigit(ch) || ch == '.') {
            buf += ch;
            display.fillRect(0, 52, SCREEN_WIDTH, 12, SSD1306_BLACK);
            display.setCursor(0, 52);
            display.print(buf);
            display.display();
          }
        }
        delay(50);
      }
      display.fillRect(0, 36, SCREEN_WIDTH, 28, SSD1306_BLACK);
      display.setCursor(0, 36);
      display.println("Calibration timeout");
      display.display();
      delay(1000);
      calib_done: ;
    }
  }

  delay(300);
}