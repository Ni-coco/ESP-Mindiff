#pragma once
#include <Arduino.h>
#include "GlobalState.h"
#include "Scale.h"
#include "ConfigManager.h"

// Parse les commandes JSON recues depuis l'app et les execute.
//
// Commandes supportees :
//   {"cmd":"tare"}
//   {"cmd":"restart"}                            → reboot sans effacer la config
//   {"cmd":"reset"}                              → efface config + reboot
//   {"cmd":"rename","name":"MaBalance"}
//   {"cmd":"wifi","ssid":"...","password":"..."}
class CommandHandler {
public:
    CommandHandler(Scale& scale, GlobalState& state, ConfigManager& config);
    void handle(const String& json);

private:
    Scale&         _scale;
    GlobalState&   _state;
    ConfigManager& _config;
};
