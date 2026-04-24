#include "TaskDisplay.h"
#include "../AppState.h"
#include "../GlobalState.h"

static Display* _display = nullptr;

static void run(void*) {
    for (;;) {
        BalanceStatus snap = gState.snapshot();

        xSemaphoreTake(displayMutex, portMAX_DELAY);
        _display->render(snap);
        xSemaphoreGive(displayMutex);

        vTaskDelay(pdMS_TO_TICKS(200));
    }
}

void startTaskDisplay(Display* display) {
    _display = display;
    // Core 0 : tourne en parallèle de setup() qui est sur Core 1
    xTaskCreatePinnedToCore(run, "Display", 4096, nullptr, 1, nullptr, 0);
}
