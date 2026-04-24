#pragma once
#include "Display.h"

// Lance la tâche d'affichage sur Core 0.
// TaskDisplay est la seule tâche qui appelle display.render().
// Elle prend displayMutex avant chaque rendu pour éviter les conflits
// avec TaskCalibration qui peut afficher des overlays.
void startTaskDisplay(Display* display);
