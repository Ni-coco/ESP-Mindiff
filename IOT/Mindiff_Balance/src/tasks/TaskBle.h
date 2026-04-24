#pragma once

// Lance la tâche BLE provisioning sur Core 0.
// Quand des credentials arrivent via BLE, les copie dans gCredsJson
// et donne credsSem pour débloquer setup().
// Sans effet si compilé avec -DNO_BLE (Wokwi).
void startTaskBle(const char* deviceName);

// Arrête le BLE et supprime la tâche.
void stopTaskBle();
