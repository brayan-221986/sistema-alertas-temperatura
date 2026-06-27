#include <Arduino.h>
#include <Preferences.h>
#include <ArduinoJson.h>
#include "SensorTemp.h"
#include "LedControl.h"
#include "WifiManager.h"
#include "MqttManager.h"
#include "secrets.h"

#define PIN_SENSOR_DS18B20 4
#define PIN_LED_ROJO 5

#define TOPICO_TEMPERATURA "esp32/alertas/temperatura"
#define TOPICO_ESTADO      "esp32/alertas/estado"
#define TOPICO_MENSAJE     "esp32/alertas/mensaje"
#define TOPICO_CONFIG      "esp32/alertas/config"

SensorTemp sensorTemperatura(PIN_SENSOR_DS18B20);
LedControl ledAlerta(PIN_LED_ROJO);
WifiManager wifi(WIFI_SSID, WIFI_PASSWORD);
MqttManager mqtt(MQTT_BROKER_HOST, MQTT_BROKER_PORT, MQTT_USER, MQTT_PASSWORD, "esp32-alertas-01");
Preferences preferencias;

float umbralMin = 10.0;
float umbralMax = 30.0;
String msgMin = "Temperatura muy baja: {temp} C - Activar calefaccion";
String msgMax = "Temperatura muy caliente: {temp} C - Enfriar almacen";
String msgNormal = "Temperatura dentro del rango";

void cargarConfig() {
    umbralMin = preferencias.getFloat("umbralMin", 10.0);
    umbralMax = preferencias.getFloat("umbralMax", 30.0);
    msgMin = preferencias.getString("msgMin", "Temperatura muy baja: {temp} C - Activar calefaccion");
    msgMax = preferencias.getString("msgMax", "Temperatura muy caliente: {temp} C - Enfriar almacen");
    msgNormal = preferencias.getString("msgNormal", "Temperatura dentro del rango");

    Serial.println(F("[CONFIG] Cargada de NVS:"));
    Serial.print(F("  min: ")); Serial.println(umbralMin);
    Serial.print(F("  max: ")); Serial.println(umbralMax);
}

void guardarConfig(float min, float max, const String& minMsg, const String& maxMsg, const String& normMsg) {
    preferencias.putFloat("umbralMin", min);
    preferencias.putFloat("umbralMax", max);
    preferencias.putString("msgMin", minMsg);
    preferencias.putString("msgMax", maxMsg);
    preferencias.putString("msgNormal", normMsg);
    Serial.println(F("[CONFIG] Guardada en NVS"));
}

String armarMensaje(const String& plantilla, float temperatura) {
    String resultado = plantilla;
    resultado.replace("{temp}", String(temperatura, 1));
    return resultado;
}

void manejarConfig(char* topico, byte* payload, unsigned int longitud) {
    payload[longitud] = '\0';
    String jsonStr = String((char*)payload);
    Serial.print(F("[CONFIG] Recibido: "));
    Serial.println(jsonStr);

    JsonDocument doc;
    DeserializationError error = deserializeJson(doc, jsonStr);
    if (error) {
        Serial.print(F("[CONFIG] Error JSON: "));
        Serial.println(error.c_str());
        return;
    }

    float min = doc["min"] | umbralMin;
    float max = doc["max"] | umbralMax;
    String minMsg = doc["msg_min"] | msgMin;
    String maxMsg = doc["msg_max"] | msgMax;
    String normMsg = doc["msg_normal"] | msgNormal;

    guardarConfig(min, max, minMsg, maxMsg, normMsg);
    cargarConfig();
}

void setup() {
    Serial.begin(115200);
    delay(1000);

    Serial.println(F("=== Modulo: Umbrales configurables ==="));

    ledAlerta.iniciar();

    if (!sensorTemperatura.iniciar()) {
        Serial.println(F("[ERROR] DS18B20 no detectado."));
    }

    preferencias.begin("alertas", false);
    cargarConfig();

    wifi.conectar();
    mqtt.iniciar();
    mqtt.setCallback(manejarConfig);
}

void loop() {
    if (!wifi.estaConectado()) {
        wifi.conectar();
    }

    if (mqtt.asegurarConexion()) {
        static bool suscrito = false;
        if (!suscrito) {
            mqtt.suscribir(TOPICO_CONFIG);
            suscrito = true;
        }
    }

    float temperatura = sensorTemperatura.leerTemperaturaC();

    Serial.print(F("Temperatura actual: "));
    Serial.print(temperatura);
    Serial.println(F(" C"));

    char bufferTemp[8];
    dtostrf(temperatura, 4, 2, bufferTemp);
    mqtt.publicar(TOPICO_TEMPERATURA, bufferTemp);

    String estado;
    String mensaje;
    bool alerta;

    if (temperatura < umbralMin) {
        estado = "ALERTA_MIN";
        mensaje = armarMensaje(msgMin, temperatura);
        alerta = true;
    } else if (temperatura > umbralMax) {
        estado = "ALERTA_MAX";
        mensaje = armarMensaje(msgMax, temperatura);
        alerta = true;
    } else {
        estado = "NORMAL";
        mensaje = armarMensaje(msgNormal, temperatura);
        alerta = false;
    }

    if (alerta) {
        ledAlerta.encender();
        Serial.print(F(">>> ")); Serial.println(estado);
    } else {
        ledAlerta.apagar();
    }

    mqtt.publicar(TOPICO_ESTADO, estado.c_str());
    mqtt.publicar(TOPICO_MENSAJE, mensaje.c_str());

    delay(2000);
}
