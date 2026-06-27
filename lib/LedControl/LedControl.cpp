#include "LedControl.h"

LedControl::LedControl(uint8_t pin) : _pin(pin) {}

void LedControl::iniciar() {
    pinMode(_pin, OUTPUT);
    apagar(); // Estado inicial seguro: LED apagado al arrancar
}

void LedControl::encender() {
    digitalWrite(_pin, HIGH);
}

void LedControl::apagar() {
    digitalWrite(_pin, LOW);
}
