#pragma once

// Lance la tâche BLE sur Core 0. Tourne indéfiniment après le boot.
//
// Rôles :
//   - Reçoit les credentials WiFi via PROVISION_CHAR → donne credsSem
//   - Reçoit les commandes JSON via CMD_CHAR → pousse dans qCalibCmd
//   - Notifie le poids live toutes les 500ms via WEIGHT_CHAR
//
// Idempotent : appels multiples ignorés si déjà démarré.
// Sans effet si compilé avec -DNO_BLE (Wokwi).
void startTaskBle(const char* deviceName);
