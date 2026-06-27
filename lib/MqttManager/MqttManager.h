#ifndef MQTT_MANAGER_H
#define MQTT_MANAGER_H

#include <Arduino.h>

class MqttManager {
public:
    MqttManager(const char* host, uint16_t port, const char* usuario,
                const char* clave, const char* idCliente);

    void iniciar();
    bool asegurarConexion();
    void publicar(const char* topico, const char* valor);

private:
    const char* _host;
    uint16_t _port;
    const char* _usuario;
    const char* _clave;
    const char* _idCliente;
};

#endif
