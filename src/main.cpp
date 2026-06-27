#include <Arduino.h>
#include "SensorTemp.h"
#include "LedControl.h"

// --- Definición de pines ---
// GPIO4: línea DATA del DS18B20 (protocolo 1-Wire).
#define PIN_SENSOR_DS18B20 4
// GPIO5: LED rojo de alerta, vía resistencia de 220Ω hacia GND.
#define PIN_LED_ROJO 5

// Umbral temporal solo para validar el módulo. En etapas futuras
// esto se sustituirá por detección real de outliers antes de
// enviar el dato al broker MQTT.
#define UMBRAL_TEMPERATURA_C 30.0

SensorTemp sensorTemperatura(PIN_SENSOR_DS18B20);
LedControl ledAlerta(PIN_LED_ROJO);

void setup() {
    Serial.begin(115200);
    delay(1000); // Da tiempo a que el monitor serie se conecte

    Serial.println(F("=== Modulo 1: Sensor DS18B20 + LED ==="));

    ledAlerta.iniciar();

    if (!sensorTemperatura.iniciar()) {
        Serial.println(F("[ERROR] DS18B20 no detectado. Revisa GND, DATA y la resistencia pull-up."));
    }
}

void loop() {
    float temperatura = sensorTemperatura.leerTemperaturaC();

    Serial.print(F("Temperatura actual: "));
    Serial.print(temperatura);
    Serial.println(F(" C"));

    // Lógica simple solo para esta etapa: se reemplazará por
    // detección de outliers + envío MQTT en módulos posteriores.
    if (temperatura > UMBRAL_TEMPERATURA_C) {
        ledAlerta.encender();
        Serial.println(F(">>> ALERTA: temperatura sobre el umbral <<<"));
    } else {
        ledAlerta.apagar();
    }

    delay(2000); // Lectura cada 2s (temporal, solo para pruebas)
}
