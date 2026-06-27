#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <Arduino.h>

class WifiManager {
public:
    WifiManager(const char* ssid, const char* password);

    bool conectar();
    bool estaConectado();

private:
    const char* _ssid;
    const char* _password;
};

#endif
