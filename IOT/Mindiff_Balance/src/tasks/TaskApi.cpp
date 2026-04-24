#include "TaskApi.h"
#include "../AppState.h"
#include "../GlobalState.h"

static ApiClient** _apiRef = nullptr;

static void run(void*) {
    float kg;

    for (;;) {
        // Bloque jusqu'à ce que TaskScale envoie un poids stable
        if (xQueueReceive(qStableWeight, &kg, portMAX_DELAY) != pdTRUE) continue;

        ApiClient* api = *_apiRef;
        if (!api) {
            Serial.println("[API] Client non initialisé");
            continue;
        }

        bool ok = api->postWeight(kg);

        gState.update([ok](BalanceStatus& s) {
            s.apiOk     = ok;
            s.lastEvent = ok ? "Envoye !" : "Erreur POST";
        });

        Serial.printf("[API] POST %.3f kg → %s\n", kg, ok ? "OK" : "ERREUR");
    }
}

void startTaskApi(ApiClient** apiRef) {
    _apiRef = apiRef;
    // Core 0 : même core que le stack WiFi → moins de overhead inter-core
    // Stack 8192 : HTTPClient a besoin de beaucoup de mémoire pour les connexions TLS
    xTaskCreatePinnedToCore(run, "Api", 8192, nullptr, 1, nullptr, 0);
}
