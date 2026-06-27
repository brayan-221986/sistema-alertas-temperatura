#ifndef SENSOR_TEMP_H
#define SENSOR_TEMP_H

#include <Arduino.h>

// Módulo encargado únicamente de la lectura del sensor DS18B20.
// Encapsula el protocolo 1-Wire para que main.cpp no necesite
// conocer nada de OneWire/DallasTemperature directamente.
class SensorTemp {
public:
    // pinDatos: pin GPIO conectado a la línea DATA del DS18B20.
    explicit SensorTemp(uint8_t pinDatos);

    // Inicializa el bus 1-Wire y verifica que el sensor responde.
    // Debe llamarse una sola vez, dentro de setup().
    // Devuelve false si no se detectó ningún sensor en el bus.
    bool iniciar();

    // Solicita una nueva conversión y devuelve la temperatura en °C.
    // Devuelve -127.0 (DEVICE_DISCONNECTED_C) si hay error de lectura
    // (cable suelto, resistencia pull-up ausente, etc).
    float leerTemperaturaC();

private:
    uint8_t _pinDatos;
};

#endif
