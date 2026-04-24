#include "AppState.h"

SemaphoreHandle_t scaleMutex    = nullptr;
SemaphoreHandle_t displayMutex  = nullptr;
QueueHandle_t     qStableWeight = nullptr;
SemaphoreHandle_t credsSem      = nullptr;
char              gCredsJson[512] = {};

void initAppState() {
    scaleMutex    = xSemaphoreCreateMutex();
    displayMutex  = xSemaphoreCreateMutex();
    qStableWeight = xQueueCreate(1, sizeof(float)); // capacité 1 : un poids stable en attente
    credsSem      = xSemaphoreCreateBinary();
}
