#ifndef LED_CONTROL_H
#define LED_CONTROL_H

#include <Arduino.h>

// Módulo que SOLO sabe encender/apagar el LED. No conoce nada de
// temperatura ni de umbrales — esa decisión vive en main.cpp.
// Esta separación nos permitirá, en módulos futuros, cambiar la
// lógica de alerta sin tocar este archivo.
class LedControl {
public:
    explicit LedControl(uint8_t pin);

    void iniciar();
    void encender();
    void apagar();

private:
    uint8_t _pin;
};

#endif
