#include "SensorTemp.h"
#include <OneWire.h>
#include <DallasTemperature.h>

// Punteros estáticos al bus y al gestor de sensores. Se mantienen
// ocultos aquí (no en el .h) para que el resto del proyecto no
// dependa de las librerías OneWire/DallasTemperature directamente.
static OneWire* busOneWire = nullptr;
static DallasTemperature* sensores = nullptr;

SensorTemp::SensorTemp(uint8_t pinDatos) : _pinDatos(pinDatos) {}

bool SensorTemp::iniciar() {
    // Crea el bus 1-Wire sobre el pin indicado y lo asocia al
    // gestor DallasTemperature.
    busOneWire = new OneWire(_pinDatos);
    sensores = new DallasTemperature(busOneWire);
    sensores->begin();

    // getDeviceCount() recorre el bus y cuenta cuántos dispositivos
    // 1-Wire respondieron. Si es 0, el sensor no está bien cableado
    // (revisar GND, pull-up o el propio pin de datos).
    int cantidad = sensores->getDeviceCount();

    Serial.print(F("[SensorTemp] Sensores DS18B20 detectados: "));
    Serial.println(cantidad);

    return cantidad > 0;
}

float SensorTemp::leerTemperaturaC() {
    // requestTemperatures() ordena a TODOS los sensores del bus
    // iniciar la conversión interna. A 12 bits de resolución
    // (la resolución por defecto del DS18B20) tarda hasta ~750ms.
    sensores->requestTemperatures();

    // getTempCByIndex(0): como solo hay un sensor en el bus,
    // leemos el dispositivo en la posición 0.
    return sensores->getTempCByIndex(0);
}
