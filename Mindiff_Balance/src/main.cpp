#include <Wire.h>
#include "HX711.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

// HX711 circuit wiring
const int LOADCELL_DOUT_PIN = 16; // D16
const int LOADCELL_SCK_PIN = 4;   // D4

// I2C for SSD1306 (ESP32 defaults: SDA=21, SCL=22)
// If you use different pins, init Wire accordingly in setup().

HX711 scale;

// OLED display (128x64)
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
// If your display has a reset pin, put it instead of -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

// Calibration: change this using serial calibration procedure below
float calibration_factor = 1000.0; // default, tune to your setup

void printHelp() {
  // Draw static commands area at bottom of the screen once
  display.setTextSize(1);
  display.setCursor(0, 40);
  display.println("Commands:");
  display.println(" t : tare");
  display.println(" c : calibrate");
  display.println(" + / - : adjust cal");
  display.display();
}

void setup() {
  Serial.begin(57600);
  delay(10);

  // init scale
  scale.begin(LOADCELL_DOUT_PIN, LOADCELL_SCK_PIN);
  scale.set_scale(calibration_factor);
  scale.tare(); // reset the scale to 0

  // init display
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
  printHelp();
}

void loop() {
  if (!scale.is_ready()) {
    Serial.println("HX711 not found.");
    display.clearDisplay();
    display.setCursor(0, 0);
    display.println("HX711 not found");
    display.display();
    delay(1000);
    return;
  }

  // Read weight (units depend on calibration factor). We'll display in kg.
  float weight_g = scale.get_units(10); // assume calibration gives grams
  float weight_kg = weight_g / 1000.0;

  // Update only the upper area (weight) to avoid flicker of commands
  display.fillRect(0, 0, SCREEN_WIDTH, 36, SSD1306_BLACK); // clear weight area
  display.setTextSize(2);
  display.setCursor(0, 0);
  display.print(weight_kg, 3);
  display.print(" ");
  display.println("kg");

  display.setTextSize(1);
  display.setCursor(0, 30);
  display.print("Cal: ");
  display.println(calibration_factor, 1);
  display.display();
  // Serial commands for tare/calibration; feedback shown on OLED (not serial)
  if (Serial.available()) {
    char c = Serial.read();
    if (c == 't') {
      scale.tare();
      // show confirmation in small overlay
      display.fillRect(20, 18, 88, 12, SSD1306_BLACK);
      display.setTextSize(1);
      display.setCursor(24, 20);
      display.println("Tare: done");
      display.display();
      delay(800);
    } else if (c == '+') {
      calibration_factor *= 0.95; // increase sensitivity
      scale.set_scale(calibration_factor);
      // update cal shown in weight area next loop
    } else if (c == '-') {
      calibration_factor *= 1.05; // decrease sensitivity
      scale.set_scale(calibration_factor);
      // update cal shown in weight area next loop
    } else if (c == 'c') {
      // Enter calibration input mode: read numeric value with timeout
      unsigned long start = millis();
      const unsigned long timeout = 15000; // 15s to enter value
      String buf = "";

      // Prompt on OLED (do not clear commands area)
      display.fillRect(0, 36, SCREEN_WIDTH, 28, SSD1306_BLACK);
      display.setTextSize(1);
      display.setCursor(0, 36);
      display.println("Calibrate:");
      display.println("Place known weight");
      display.println("Type grams within 15s");
      display.display();

      // non-blocking read with timeout
      while (millis() - start < timeout) {
        while (Serial.available()) {
          char ch = Serial.read();
          if (ch == '\r') continue;
          if (ch == '\n') {
            // process
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
          } else if (isDigit(ch) || ch == '.' ) {
            buf += ch;
            // show entered chars
            display.fillRect(0, 52, SCREEN_WIDTH, 12, SSD1306_BLACK);
            display.setCursor(0, 52);
            display.print(buf);
            display.display();
          }
        }
        // small delay to avoid busy loop
        delay(50);
      }
      // timeout
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