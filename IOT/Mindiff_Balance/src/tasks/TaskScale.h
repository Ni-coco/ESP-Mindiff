#pragma once
#include "Scale.h"

// Lance la tâche de lecture de la balance sur Core 1.
// Lit le poids toutes les 300ms, détecte la stabilité,
// et envoie le poids stable dans qStableWeight pour TaskApi.
void startTaskScale(Scale* scale);
