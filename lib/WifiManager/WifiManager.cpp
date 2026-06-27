#include "WifiManager.h"
#include <WiFi.h>

WifiManager::WifiManager(const char* ssid, const char* password)
    : _ssid(ssid), _password(password) {}

bool WifiManager::conectar() {
    Serial.print(F("[WiFi] Conectando a "));
    Serial.println(_ssid);

    WiFi.mode(WIFI_STA);
    WiFi.begin(_ssid, _password);

    uint8_t intentos = 0;
    while (WiFi.status() != WL_CONNECTED && intentos < 30) {
        delay(500);
        Serial.print(F("."));
        intentos++;
    }
    Serial.println();

    if (WiFi.status() == WL_CONNECTED) {
        Serial.print(F("[WiFi] Conectado. IP: "));
        Serial.println(WiFi.localIP());
        return true;
    }

    Serial.println(F("[WiFi] No se pudo conectar tras 15s."));
    return false;
}

bool WifiManager::estaConectado() {
    return WiFi.status() == WL_CONNECTED;
}
