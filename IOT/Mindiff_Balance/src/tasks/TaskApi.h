#pragma once
#include "ApiClient.h"

// Lance la tâche API sur Core 0 (même core que le stack WiFi).
// Bloque sur qStableWeight et envoie dès qu'un poids stable arrive.
// apiRef est un pointeur sur le pointeur ApiClient* pour pouvoir
// le réassigner après reconnexion WiFi.
void startTaskApi(ApiClient** apiRef);
