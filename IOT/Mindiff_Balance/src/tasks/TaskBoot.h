#pragma once

// Lance la tâche de boot sur Core 1.
//
// Responsabilités :
//   1. Provisioning  — attend les credentials (BLE ou Serial, sans timeout)
//   2. Connexion     — tente la connexion WiFi
//   3. WiFi échoué   — affiche l'erreur, efface la config, retour provisioning
//   4. Opérationnel  — lance toutes les tâches métier
//   5. Surveillance  — surveille le WiFi et reconnecte si besoin
//
// main.cpp n'a pas à connaître les détails de ce cycle.
void startTaskBoot();
