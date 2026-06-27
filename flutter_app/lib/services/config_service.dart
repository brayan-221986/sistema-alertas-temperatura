import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'mqtt_service.dart';

class ConfigService {
  static const String _keyMin = 'umbral_min';
  static const String _keyMax = 'umbral_max';
  static const String _keyMsgMin = 'msg_min';
  static const String _keyMsgMax = 'msg_max';
  static const String _keyMsgNormal = 'msg_normal';

  final MqttService _mqtt;

  ConfigService(this._mqtt);

  Future<Map<String, dynamic>> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'min': prefs.getDouble(_keyMin) ?? 10.0,
      'max': prefs.getDouble(_keyMax) ?? 30.0,
      'msg_min': prefs.getString(_keyMsgMin) ?? 'Temperatura muy baja: {temp} C - Activar calefaccion',
      'msg_max': prefs.getString(_keyMsgMax) ?? 'Temperatura muy caliente: {temp} C - Enfriar almacen',
      'msg_normal': prefs.getString(_keyMsgNormal) ?? 'Temperatura dentro del rango',
    };
  }

  Future<void> guardar(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyMin, (config['min'] as num).toDouble());
    await prefs.setDouble(_keyMax, (config['max'] as num).toDouble());
    await prefs.setString(_keyMsgMin, config['msg_min'] as String);
    await prefs.setString(_keyMsgMax, config['msg_max'] as String);
    await prefs.setString(_keyMsgNormal, config['msg_normal'] as String);

    final json = jsonEncode(config);
    _mqtt.publicar('esp32/alertas/config', json);
  }
}
