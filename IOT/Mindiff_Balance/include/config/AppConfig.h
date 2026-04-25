#pragma once

// ── Pins HX711 ───────────────────────────────────────────────────────────────
#define PIN_DOUT 13
#define PIN_SCK  14

// ── Calibration ──────────────────────────────────────────────────────────────
// Peuvent être overridés par build_flags dans platformio.ini (par env)
#ifndef DEFAULT_CALIB_FACTOR
#define DEFAULT_CALIB_FACTOR 1000.0f
#endif

#ifndef SIM_WEIGHT_MULTIPLIER
#define SIM_WEIGHT_MULTIPLIER 1.0f
#endif

// ── Détection stabilité (taskScale) ─────────────────────────────────────────
#define SCALE_SAMPLES      5
#define SCALE_THRESHOLD_KG 0.050f   // écart max entre min/max pour "stable"
#define SCALE_MIN_KG       1.0f     // poids minimum avant envoi API

// ── Tâches FreeRTOS — stack sizes (bytes) ────────────────────────────────────
#define STACK_DISPLAY   4096
#define STACK_COMMANDS  8192
#define STACK_BOOT      4096
#define STACK_SCALE     2048
#define STACK_API       8192
#define STACK_CALIB     2048

// ── Tâches FreeRTOS — délais (ms) ────────────────────────────────────────────
#define DELAY_DISPLAY_MS       200
#define DELAY_SCALE_MS         300
#define DELAY_BLE_NOTIFY_MS    500
#define DELAY_SERIAL_MS         50
#define DELAY_WIFI_MONITOR_MS 5000
#define DELAY_WIFI_FAILED_MS  2000
