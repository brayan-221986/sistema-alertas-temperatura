#include "MqttManager.h"
#include <WiFi.h>
#include <PubSubClient.h>

static WiFiClient clienteTCP;
static PubSubClient clienteMqtt(clienteTCP);

MqttManager::MqttManager(const char* host, uint16_t port, const char* usuario,
                          const char* clave, const char* idCliente)
    : _host(host), _port(port), _usuario(usuario), _clave(clave), _idCliente(idCliente) {}

void MqttManager::iniciar() {
    clienteMqtt.setServer(_host, _port);
}

bool MqttManager::asegurarConexion() {
    if (clienteMqtt.connected()) {
        clienteMqtt.loop();
        return true;
    }

    Serial.print(F("[MQTT] Conectando a "));
    Serial.print(_host);
    Serial.print(F(":"));
    Serial.println(_port);

    if (clienteMqtt.connect(_idCliente, _usuario, _clave)) {
        Serial.println(F("[MQTT] Conectado."));
        return true;
    }

    Serial.print(F("[MQTT] Fallo de conexion, codigo: "));
    Serial.println(clienteMqtt.state());
    return false;
}

void MqttManager::publicar(const char* topico, const char* valor) {
    if (!clienteMqtt.connected()) return;

    bool exito = clienteMqtt.publish(topico, valor);

    Serial.print(F("[MQTT] Publicado en '"));
    Serial.print(topico);
    Serial.print(F("': "));
    Serial.print(valor);
    Serial.println(exito ? F(" (OK)") : F(" (FALLO)"));
}
