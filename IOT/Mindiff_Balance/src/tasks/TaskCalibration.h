#pragma once
#include "Scale.h"
#include "Display.h"
#include "ConfigManager.h"

// Lance la tâche de calibration sur Core 1.
// Consomme les CalibCommand depuis qCalibCmd (poussées par TaskCalibSerial ou BLE).
// Protocole JSON identique des deux côtés :
//   {"cmd":"tare"}                 → remet le zéro
//   {"cmd":"calibrate","kg":1.0}   → calibre (tare préalable requis côté app)
//   {"cmd":"adjust","dir":"+"}     → ajuste le facteur vers le haut
//   {"cmd":"adjust","dir":"-"}     → ajuste le facteur vers le bas
//
// Le nouveau facteur est automatiquement persisté dans ConfigManager (NVS).
void startTaskCalibration(Scale* scale, Display* display, ConfigManager* config);
