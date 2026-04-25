#pragma once
#include "ApiClient.h"
#include "state/AppState.h"
#include "state/GlobalState.h"

class ApiSender {
public:
    ApiSender(ApiClient*& api) : _api(api) {}

    void loop() {
        float kg;
        if (xQueueReceive(qStableWeight, &kg, portMAX_DELAY) != pdTRUE) return;
        if (!_api) return;

        bool ok = _api->postWeight(kg);
        gState.update([ok](BalanceStatus& s) {
            s.apiOk     = ok;
            s.lastEvent = ok ? "Envoye !" : "Erreur API";
        });
    }

private:
    ApiClient*& _api;
};
