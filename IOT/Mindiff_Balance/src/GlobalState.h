#pragma once
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>
#include "BalanceStatus.h"

// ─── État runtime partagé entre toutes les tâches ─────────────────────────────
//
// Usage :
//   gState.update([](BalanceStatus& s) { s.weightKg = 1.5f; });
//   BalanceStatus snap = gState.snapshot(); // pour TaskDisplay
//   BalanceState  st   = gState.state();    // pour tester l'état courant
//
class GlobalState {
public:
    // Appeler une seule fois au début de setup(), avant de créer des tâches
    void init();

    // Modifier l'état de façon thread-safe via un lambda
    template<typename F>
    void update(F fn) {
        xSemaphoreTake(_mutex, portMAX_DELAY);
        fn(_status);
        xSemaphoreGive(_mutex);
    }

    // Copie thread-safe complète (utilisée par TaskDisplay)
    BalanceStatus snapshot() const;

    // Lire l'état courant sans copier tout le struct
    BalanceState state() const;

private:
    SemaphoreHandle_t _mutex  = nullptr;
    BalanceStatus     _status = {};
};

extern GlobalState gState;
