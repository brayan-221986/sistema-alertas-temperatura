#include <Arduino.h>
#include "SensorTemp.h"
#include "LedControl.h"
#include "WifiManager.h"
#include "MqttManager.h"
#include "secrets.h"

#define PIN_SENSOR_DS18B20 4
#define PIN_LED_ROJO 5

#define UMBRAL_TEMPERATURA_C 30.0

#define TOPICO_TEMPERATURA "esp32/alertas/temperatura"
#define TOPICO_ESTADO      "esp32/alertas/estado"

SensorTemp sensorTemperatura(PIN_SENSOR_DS18B20);
LedControl ledAlerta(PIN_LED_ROJO);
WifiManager wifi(WIFI_SSID, WIFI_PASSWORD);
MqttManager mqtt(MQTT_BROKER_HOST, MQTT_BROKER_PORT, MQTT_USER, MQTT_PASSWORD, "esp32-alertas-01");

void setup() {
    Serial.begin(115200);
    delay(1000);

    Serial.println(F("=== Modulo 2: WiFi + MQTT ==="));

    ledAlerta.iniciar();

    if (!sensorTemperatura.iniciar()) {
        Serial.println(F("[ERROR] DS18B20 no detectado."));
    }

    wifi.conectar();
    mqtt.iniciar();
}

void loop() {
    if (!wifi.estaConectado()) {
        wifi.conectar();
    }

    mqtt.asegurarConexion();

    float temperatura = sensorTemperatura.leerTemperaturaC();

    Serial.print(F("Temperatura actual: "));
    Serial.print(temperatura);
    Serial.println(F(" C"));

    char bufferTemp[8];
    dtostrf(temperatura, 4, 2, bufferTemp);
    mqtt.publicar(TOPICO_TEMPERATURA, bufferTemp);

    if (temperatura > UMBRAL_TEMPERATURA_C) {
        ledAlerta.encender();
        mqtt.publicar(TOPICO_ESTADO, "ALERTA");
    } else {
        ledAlerta.apagar();
        mqtt.publicar(TOPICO_ESTADO, "NORMAL");
    }

    delay(2000);
}
