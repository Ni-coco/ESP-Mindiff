#pragma once
#include "Scale.h"
#include "Display.h"
#include "ConfigManager.h"

// Lance la tâche de calibration Serial sur Core 1.
// Commandes disponibles (envoyer un caractère via Serial) :
//   t  → tare (zéro)
//   +  → augmente le facteur de calibration
//   -  → diminue le facteur de calibration
//   c  → calibration avec poids connu (15s pour entrer la valeur en grammes)
//
// Le nouveau facteur est automatiquement persisté dans ConfigManager.
void startTaskCalibration(Scale* scale, Display* display, ConfigManager* config);
