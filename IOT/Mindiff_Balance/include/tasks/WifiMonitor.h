#pragma once
#include "WifiManager.h"
#include "state/GlobalState.h"

// Surveille la connexion WiFi et met à jour le GlobalState.
// WifiManager (lib) ne connaît pas le GlobalState — c'est ce wrapper qui fait le lien.
class WifiMonitor {
public:
    WifiMonitor(WifiManager& wifi) : _wifi(wifi) {}

    void loop() {
        bool ok = _wifi.loop();
        gState.update([ok](BalanceStatus& s) {
            s.wifiOk    = ok;
            s.lastEvent = ok ? s.lastEvent : "WiFi perdu...";
        });
    }

private:
    WifiManager& _wifi;
};
