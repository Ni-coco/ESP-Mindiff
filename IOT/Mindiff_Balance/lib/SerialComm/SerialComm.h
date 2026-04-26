#pragma once
#include "IComm.h"

class SerialComm : public IComm {
public:
    SerialComm(GlobalState& state, CommandHandler& cmdHandler)
        : IComm(state, cmdHandler) {}

    void   begin(const String& deviceName) override;
    void   send(const String& json)        override;
    String receive()                        override;
    bool   isConnected()                    override;

private:
    String _buf;
};
