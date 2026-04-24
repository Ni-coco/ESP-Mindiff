#pragma once
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>
#include <freertos/semphr.h>

// ─── Mutex accès hardware partagé ─────────────────────────────────────────────
extern SemaphoreHandle_t scaleMutex;    // TaskScale + TaskCalibration → HX711
extern SemaphoreHandle_t displayMutex; // TaskDisplay + TaskCalibration → OLED

// ─── Queue inter-tâches ───────────────────────────────────────────────────────
extern QueueHandle_t qStableWeight;    // TaskScale → TaskApi  (float kg)

// ─── Provisioning ────────────────────────────────────────────────────────────
extern SemaphoreHandle_t credsSem;       // signalé quand les credentials sont prêts
extern char              gCredsJson[512]; // JSON brut reçu (BLE ou Serial)

// ─── Initialisation (appelée depuis setup(), après gState.init()) ─────────────
void initAppState();
