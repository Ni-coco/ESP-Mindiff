#pragma once
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>
#include <freertos/semphr.h>

// ── Mutex accès hardware partagé ─────────────────────────────────────────────
extern SemaphoreHandle_t scaleMutex;    // Scale  ←→ ScaleReader + CalibHandler
extern SemaphoreHandle_t displayMutex;  // Display ←→ taskDisplay + CalibHandler

// ── Queues inter-tâches ───────────────────────────────────────────────────────
extern QueueHandle_t qStableWeight;    // ScaleReader → ApiSender    (float kg)
extern QueueHandle_t qCalibCmd;        // CommandsHandler → CalibHandler

// ── Provisioning ─────────────────────────────────────────────────────────────
extern SemaphoreHandle_t credsSem;         // signalé par CommandsHandler (BLE)
extern char              gCredsJson[512];  // JSON brut reçu (BLE ou Serial)

// Définis et initialisés dans main.cpp (setup)
