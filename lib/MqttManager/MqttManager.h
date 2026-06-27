#ifndef MQTT_MANAGER_H
#define MQTT_MANAGER_H

#include <Arduino.h>
#include <PubSubClient.h>

typedef void (*MqttCallback)(char* topico, byte* payload, unsigned int longitud);

class MqttManager {
public:
    MqttManager(const char* host, uint16_t port, const char* usuario,
                const char* clave, const char* idCliente);

    void iniciar();
    bool asegurarConexion();
    void publicar(const char* topico, const char* valor);
    void suscribir(const char* topico);
    void setCallback(MqttCallback callback);

private:
    const char* _host;
    uint16_t _port;
    const char* _usuario;
    const char* _clave;
    const char* _idCliente;
};

#endif
