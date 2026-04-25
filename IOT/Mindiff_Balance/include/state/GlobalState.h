#pragma once
#include <freertos/FreeRTOS.h>
#include <freertos/semphr.h>
#include "state/BalanceStatus.h"

// État global partagé entre toutes les tâches — accès thread-safe via mutex.
//
// Usage :
//   gState.update([](BalanceStatus& s) { s.weightKg = 1.5f; });
//   BalanceStatus snap = gState.snapshot();
//   BalanceState  st   = gState.state();
class GlobalState {
public:
    void init() {
        _mutex = xSemaphoreCreateMutex();
    }

    template<typename F>
    void update(F fn) {
        xSemaphoreTake(_mutex, portMAX_DELAY);
        fn(_status);
        xSemaphoreGive(_mutex);
    }

    BalanceStatus snapshot() const {
        xSemaphoreTake(_mutex, portMAX_DELAY);
        BalanceStatus copy = _status;
        xSemaphoreGive(_mutex);
        return copy;
    }

    BalanceState state() const {
        xSemaphoreTake(_mutex, portMAX_DELAY);
        BalanceState s = _status.state;
        xSemaphoreGive(_mutex);
        return s;
    }

private:
    mutable SemaphoreHandle_t _mutex  = nullptr;
    BalanceStatus             _status = {};
};

extern GlobalState gState;
