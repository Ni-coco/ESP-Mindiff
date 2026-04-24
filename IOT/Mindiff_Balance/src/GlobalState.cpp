#include "GlobalState.h"

GlobalState gState;

void GlobalState::init() {
    // Appelé depuis setup() une fois le scheduler FreeRTOS démarré
    _mutex = xSemaphoreCreateMutex();
}

BalanceStatus GlobalState::snapshot() const {
    xSemaphoreTake(_mutex, portMAX_DELAY);
    BalanceStatus copy = _status;
    xSemaphoreGive(_mutex);
    return copy;
}

BalanceState GlobalState::state() const {
    xSemaphoreTake(_mutex, portMAX_DELAY);
    BalanceState s = _status.state;
    xSemaphoreGive(_mutex);
    return s;
}
