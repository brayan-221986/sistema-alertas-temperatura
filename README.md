# Sistema de Alertas de Temperatura en Tiempo Real

Sistema IoT que lee temperatura con un sensor DS18B20 en un ESP32, la publica vía MQTT a un broker Mosquitto en AWS EC2, activa un LED rojo como alerta local cuando se supera un umbral, y notifica una app Flutter en tiempo real.

---

## Arquitectura General

```
[ESP32 + DS18B20 + LED] ---MQTT---> [Mosquitto en AWS EC2] ---MQTT---> [App Flutter]
       publica:                              |                         suscribe:
  esp32/alertas/temperatura               broker                   esp32/alertas/temperatura
  esp32/alertas/estado                                                esp32/alertas/estado
```

---

## Módulo 1 — Hardware y Firmware Base (ESP32)

### Componentes

- ESP32 DevKit
- Sensor DS18B20 (protocolo 1-Wire, digital)
- LED rojo de 5mm
- Resistencia 220Ω (para el LED)
- Resistencia 4.7kΩ (pull-up del DS18B20, solo si el breakout no la trae soldada)

### Conexión Eléctrica

```
DS18B20:
  + (VCC)  ─── 3.3V (ESP32)
  - (GND)  ─── GND  (ESP32)
  S (DATA) ─── GPIO4 (ESP32)
  ── resistencia 4.7kΩ entre + y S (si no viene soldada)

LED rojo:
  Ánodo (+) ─── GPIO5 (ESP32)
  Cátodo (-) ─── resistencia 220Ω ─── GND (ESP32)
```

### Estructura del Proyecto (PlatformIO)

```
sistema-alertas-temp/
├── .env                         # Credenciales (NO se sube a git)
├── .gitignore
├── platformio.ini               # Configuración del proyecto
├── scripts/
│   └── load_env.py              # Genera include/secrets.h desde .env
├── include/
│   └── secrets.h                # Generado automáticamente (NO se sube)
├── lib/
│   ├── SensorTemp/              # Lectura del DS18B20
│   │   ├── SensorTemp.h
│   │   └── SensorTemp.cpp
│   ├── LedControl/              # Control del LED rojo
│   │   ├── LedControl.h
│   │   └── LedControl.cpp
│   ├── WifiManager/             # Conexión WiFi
│   │   ├── WifiManager.h
│   │   └── WifiManager.cpp
│   └── MqttManager/             # Cliente MQTT (PubSubClient)
│       ├── MqttManager.h
│       └── MqttManager.cpp
└── src/
    └── main.cpp                 # Punto de entrada, orquesta todos los módulos
```

### Dependencias (`platformio.ini`)

- `paulstoffregen/OneWire @ ^2.3.7` — protocolo 1-Wire
- `milesburton/DallasTemperature @ ^3.11.0` — driver para sensores Dallas (DS18B20)
- `knolleary/PubSubClient @ ^2.8` — cliente MQTT ligero para ESP32

### Gestión de Credenciales (`.env`)

Las credenciales sensibles (WiFi, MQTT) se guardan en `.env`:

```env
WIFI_SSID=Redmi 15
WIFI_PASSWORD=123456789
MQTT_BROKER_HOST=3.14.80.113
MQTT_BROKER_PORT=1883
MQTT_USER=esp32_alertas
MQTT_PASSWORD=alertas123
```

Al compilar, `scripts/load_env.py` lee `.env` y genera `include/secrets.h` automáticamente. Ambos archivos están excluidos de git (`.gitignore`).

### Funcionamiento (Módulo 1)

1. En `setup()` se inicializan el LED (apagado) y el sensor DS18B20.
2. Cada 2 segundos se lee la temperatura del sensor.
3. Si la temperatura supera los 30.0°C (umbral temporal), se enciende el LED rojo.
4. Todo se muestra por el monitor serie a 115200 baudios.

---

## Módulo 2 — Broker MQTT + Conexión WiFi del ESP32

### Infraestructura

- **Servidor:** Instancia Ubuntu en AWS EC2 (IP: `3.14.80.113`)
- **Broker:** Mosquitto v2.0.22
- **Puerto:** 1883 (MQTT estándar, sin TLS por ahora)
- **Autenticación:** usuario/contraseña (`esp32_alertas` / `alertas123`)

### Instalación en la EC2

```bash
sudo apt update
sudo apt install -y mosquitto mosquitto-clients
```

### Configuración

Archivo: `/etc/mosquitto/conf.d/sistema-alertas.conf`

```conf
listener 1883
allow_anonymous false
password_file /etc/mosquitto/passwd
```

Crear usuario:

```bash
sudo mosquitto_passwd -c /etc/mosquitto/passwd esp32_alertas
```

Permisos (corrección necesaria en Mosquitto v2):

```bash
sudo chown mosquitto:mosquitto /etc/mosquitto/passwd
sudo chmod 640 /etc/mosquitto/passwd
sudo systemctl restart mosquitto
sudo systemctl enable mosquitto
```

### Regla de Firewall (AWS Security Group)

| Tipo | Puerto | Fuente | Descripción |
|------|--------|--------|-------------|
| Custom TCP | 1883 | IP del hogar | MQTT desde ESP32 |

### Tópicos MQTT Definidos

```
esp32/alertas/temperatura   → valor numérico de temperatura en °C
esp32/alertas/estado        → "NORMAL" o "ALERTA"
```

### Complicación y Solución

Al reiniciar Mosquitto por primera vez, falló con **exit code 13** ("Unable to open pwfile"). Causa: el archivo `passwd` fue creado por `root`, pero Mosquitto v2 corre como usuario `mosquitto` y no tenía permisos de lectura. Se solucionó con:

```bash
sudo chown mosquitto:mosquitto /etc/mosquitto/passwd
sudo chmod 640 /etc/mosquitto/passwd
```

### Funcionamiento del Firmware (Módulo 2)

El ESP32 ahora:

1. Se conecta a WiFi al iniciar (usando credenciales de `.env`)
2. Se conecta al broker MQTT en la EC2
3. Cada 2 segundos lee el DS18B20 y publica:
   - `esp32/alertas/temperatura` → valor numérico (ej: `"12.50"`)
   - `esp32/alertas/estado` → `"NORMAL"` o `"ALERTA"` según umbral
4. Reintenta conexión WiFi/MQTT si se pierde la conectividad
5. Controla el LED rojo localmente según el umbral

### Cómo Flashear y Monitorear

```bash
pio run -t upload && pio device monitor
```

### Verificación (Módulo 2)

Salida esperada en el monitor serie:

```
=== Modulo 2: WiFi + MQTT ===
[SensorTemp] Sensores DS18B20 detectados: 1
[WiFi] Conectando a Redmi 15
.
[WiFi] Conectado. IP: 10.60.69.216
[MQTT] Conectando a 3.14.80.113:1883
[MQTT] Conectado.
Temperatura actual: 12.00 C
[MQTT] Publicado en 'esp32/alertas/temperatura': 12.00 (OK)
[MQTT] Publicado en 'esp32/alertas/estado': NORMAL (OK)
```

Verificación desde laptop:

```bash
mosquitto_sub -h 3.14.80.113 -p 1883 -u esp32_alertas -P alertas123 -t "esp32/alertas/#" -v
```

---

## Próximos Pasos (Módulo 3)

- Desarrollar app Flutter que se suscriba a `esp32/alertas/#`
- Disparar alerta sonora cuando el estado sea `ALERTA`
- Detección de outliers en lugar de umbral fijo

---

## Comandos Útiles

| Acción | Comando |
|--------|---------|
| Flashear ESP32 | `pio run -t upload` |
| Monitor serie | `pio device monitor` |
| Compilar sin flashear | `pio run` |
| Ver logs de Mosquitto | `sudo journalctl -u mosquitto -f` |
| Estado del broker | `sudo systemctl status mosquitto` |
| Suscribirse a tópicos | `mosquitto_sub -h <IP> -p 1883 -u <user> -P <pass> -t "<topic>" -v` |
| Publicar un mensaje | `mosquitto_pub -h <IP> -p 1883 -u <user> -P <pass> -t "<topic>" -m "<msg>"` |
