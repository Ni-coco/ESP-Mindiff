#pragma once
#include <Arduino.h>
#include "GlobalState.h"
#include "CommandHandler.h"

class IComm {
public:
    IComm(GlobalState& state, CommandHandler& cmdHandler)
        : _state(state), _cmdHandler(cmdHandler) {}

    virtual ~IComm() {}

    virtual void   begin(const String& deviceName) = 0;
    virtual void   send(const String& json)        = 0;
    virtual String receive()                        = 0;
    virtual bool   isConnected()                    = 0;

    void loop() {
        bool nowConnected = isConnected();
        _wasConnected = nowConnected;
        _state.setConnected(nowConnected);

        // Envoie les donnees seulement si operationnel
        if (nowConnected && _state.getPhase() == AppPhase::OPERATIONAL) {
            String json = "{\"weight\":"  + String(_state.getWeight(),  2) +
                          ",\"battery\":" + String(_state.getBattery())    + "}";
            send(json);
        }

        // Envoie une reponse en attente (ex: status)
        if (nowConnected) {
            String pending = _state.takePendingResponse();
            if (pending.length() > 0) send(pending);
        }

        // Recoit les commandes dans toutes les phases
        String received = receive();
        if (received.length() > 0) {
            _cmdHandler.handle(received);
        }
    }


protected:
    GlobalState&    _state;
    CommandHandler& _cmdHandler;
    bool            _wasConnected = false;
};
