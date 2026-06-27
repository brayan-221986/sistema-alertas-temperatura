import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import '../models/sensor_data.dart';

class MqttService {
  static const String _topicoTemperatura = 'esp32/alertas/temperatura';
  static const String _topicoEstado = 'esp32/alertas/estado';

  final String host;
  final int port;
  final String usuario;
  final String clave;

  MqttServerClient? _cliente;

  double? _ultimaTemperatura;
  String? _ultimoEstado;

  final _controladorDatos = StreamController<SensorData>.broadcast();
  final _controladorConexion = StreamController<bool>.broadcast();

  Stream<SensorData> get datosSensor => _controladorDatos.stream;
  Stream<bool> get estadoConexion => _controladorConexion.stream;

  MqttService({
    required this.host,
    required this.port,
    required this.usuario,
    required this.clave,
  });

  Future<void> conectar() async {
    final idCliente = 'flutter-app-${DateTime.now().millisecondsSinceEpoch}';

    _cliente = MqttServerClient.withPort(host, idCliente, port);
    _cliente!.logging(on: true);
    _cliente!.keepAlivePeriod = 20;
    _cliente!.onConnected = _onConectado;
    _cliente!.onDisconnected = _onDesconectado;
    _cliente!.onSubscribed = (topic) => debugPrint('[MQTT] Suscrito a $topic');
    _cliente!.autoReconnect = true;

    _cliente!.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(idCliente)
        .authenticateAs(usuario, clave)
        .startClean();

    debugPrint('[MQTT] Conectando a $host:$port...');

    try {
      await _cliente!.connect();
    } catch (e) {
      debugPrint('[MQTT] Error de conexion: $e');
      _cliente?.disconnect();
      _controladorConexion.add(false);
      return;
    }

    final estado = _cliente!.connectionStatus?.state;

    if (estado == MqttConnectionState.connected) {
      debugPrint('[MQTT] Conectado exitosamente');
      _suscribirTopicos();
    } else {
      debugPrint('[MQTT] Estado final: $estado');
      _controladorConexion.add(false);
    }
  }

  void _onConectado() {
    debugPrint('[MQTT] Callback: conectado');
    _controladorConexion.add(true);
  }

  void _onDesconectado() {
    debugPrint('[MQTT] Callback: desconectado');
    _controladorConexion.add(false);
  }

  void _suscribirTopicos() {
    _cliente!.subscribe(_topicoTemperatura, MqttQos.atLeastOnce);
    _cliente!.subscribe(_topicoEstado, MqttQos.atLeastOnce);
    _cliente!.updates!.listen(_alRecibirMensaje);
  }

  void _alRecibirMensaje(List<MqttReceivedMessage<MqttMessage>> eventos) {
    final mensaje = eventos[0];
    final payload = mensaje.payload as MqttPublishMessage;
    final texto = MqttPublishPayload.bytesToStringAsString(payload.payload.message);

    if (mensaje.topic == _topicoTemperatura) {
      _ultimaTemperatura = double.tryParse(texto);
    } else if (mensaje.topic == _topicoEstado) {
      _ultimoEstado = texto;
    }

    if (_ultimaTemperatura != null && _ultimoEstado != null) {
      _controladorDatos.add(SensorData(
        temperatura: _ultimaTemperatura!,
        estado: _ultimoEstado!,
        timestamp: DateTime.now(),
      ));
    }
  }

  void desconectar() => _cliente?.disconnect();

  void liberar() {
    _controladorDatos.close();
    _controladorConexion.close();
  }
}
