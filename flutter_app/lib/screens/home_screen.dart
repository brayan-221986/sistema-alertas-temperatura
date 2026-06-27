import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sensor_data.dart';
import '../services/mqtt_service.dart';
import '../services/alert_sound_service.dart';
import '../services/notification_service.dart';
import '../services/config_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MqttService _mqtt = MqttService(
    host: 'BROKER_IP',
    port: 1883,
    usuario: 'esp32_alertas',
    clave: 'tu_password_mqtt',
  );

  final AlertSoundService _sonido = AlertSoundService();
  final NotificationService _notificaciones = NotificationService();

  late final ConfigService _configService = ConfigService(_mqtt);

  SensorData? _ultimaLectura;
  bool _conectado = false;

  double _rangoMin = 10.0;
  double _rangoMax = 30.0;
  final _ctrlMsgMin = TextEditingController();
  final _ctrlMsgMax = TextEditingController();
  final _ctrlMsgNormal = TextEditingController();
  bool _guardando = false;

  StreamSubscription? _subDatos;
  StreamSubscription? _subConexion;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    final config = await _configService.cargar();
    _rangoMin = (config['min'] as num).toDouble();
    _rangoMax = (config['max'] as num).toDouble();
    _ctrlMsgMin.text = config['msg_min'] as String;
    _ctrlMsgMax.text = config['msg_max'] as String;
    _ctrlMsgNormal.text = config['msg_normal'] as String;

    _subConexion = _mqtt.estadoConexion.listen((conectado) {
      setState(() => _conectado = conectado);
    });

    _subDatos = _mqtt.datosSensor.listen((lectura) {
      setState(() => _ultimaLectura = lectura);
      if (lectura.esAlerta) {
        _sonido.activar();
        _notificaciones.mostrarAlerta('Temperatura atipica detectada', lectura.mensaje);
      } else {
        _sonido.detener();
      }
    });

    await _mqtt.conectar();
  }

  Future<void> _guardarConfig() async {
    setState(() => _guardando = true);
    await _configService.guardar({
      'min': _rangoMin,
      'max': _rangoMax,
      'msg_min': _ctrlMsgMin.text,
      'msg_max': _ctrlMsgMax.text,
      'msg_normal': _ctrlMsgNormal.text,
    });
    setState(() => _guardando = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuracion enviada al sensor')),
      );
    }
  }

  @override
  void dispose() {
    _subDatos?.cancel();
    _subConexion?.cancel();
    _mqtt.desconectar();
    _mqtt.liberar();
    _sonido.liberar();
    _ctrlMsgMin.dispose();
    _ctrlMsgMax.dispose();
    _ctrlMsgNormal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lectura = _ultimaLectura;
    final esAlerta = lectura?.esAlerta ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Sistema de alertas - Temperatura')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            if (lectura != null && lectura.mensaje.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  lectura.mensaje,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 8),
            Text('Umbrales', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            RangeSlider(
              values: RangeValues(_rangoMin, _rangoMax),
              min: 0,
              max: 50,
              divisions: 50,
              labels: RangeLabels(
                '${_rangoMin.toInt()} °C',
                '${_rangoMax.toInt()} °C',
              ),
              onChanged: (valores) {
                setState(() {
                  _rangoMin = valores.start;
                  _rangoMax = valores.end;
                });
              },
            ),
            Text('Min: ${_rangoMin.toInt()} °C  |  Max: ${_rangoMax.toInt()} °C'),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrlMsgMin,
              decoration: const InputDecoration(
                labelText: 'Mensaje temp. baja',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrlMsgMax,
              decoration: const InputDecoration(
                labelText: 'Mensaje temp. alta',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrlMsgNormal,
              decoration: const InputDecoration(
                labelText: 'Mensaje temp. normal',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _guardando ? null : _guardarConfig,
                icon: _guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Guardar configuracion'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
