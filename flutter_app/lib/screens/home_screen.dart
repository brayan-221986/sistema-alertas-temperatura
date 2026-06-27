import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/mqtt_service.dart';
import '../services/alert_sound_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MqttService _mqtt = MqttService(
    host: '3.14.80.113',
    port: 1883,
    usuario: 'esp32_alertas',
    clave: 'alertas123',
  );

  final AlertSoundService _sonido = AlertSoundService();

  SensorData? _ultimaLectura;
  bool _conectado = false;

  StreamSubscription? _subDatos;
  StreamSubscription? _subConexion;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    _subConexion = _mqtt.estadoConexion.listen((conectado) {
      setState(() => _conectado = conectado);
    });

    _subDatos = _mqtt.datosSensor.listen((lectura) {
      setState(() => _ultimaLectura = lectura);
      lectura.esAlerta ? _sonido.activar() : _sonido.detener();
    });

    await _mqtt.conectar();
  }

  @override
  void dispose() {
    _subDatos?.cancel();
    _subConexion?.cancel();
    _mqtt.desconectar();
    _mqtt.liberar();
    _sonido.liberar();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lectura = _ultimaLectura;
    final esAlerta = lectura?.esAlerta ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Sistema de alertas - Temperatura')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _conectado ? Icons.cloud_done : Icons.cloud_off,
              color: _conectado ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(height: 16),
            Text(
              lectura != null ? '${lectura.temperatura.toStringAsFixed(2)} °C' : '-- °C',
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: esAlerta ? Colors.red : Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                lectura?.estado ?? 'SIN DATOS',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
