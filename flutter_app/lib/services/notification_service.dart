import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instancia = NotificationService._interno();
  factory NotificationService() => _instancia;
  NotificationService._interno();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _idCanal = 'alertas_temperatura';
  static const String _nombreCanal = 'Alertas de temperatura';
  static const String _descripcionCanal = 'Avisos cuando la temperatura sale de rango';
  static const int _idNotificacionAlerta = 1;

  Future<void> iniciar() async {
    const configuracionAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const configuracion = InitializationSettings(android: configuracionAndroid);
    await _plugin.initialize(configuracion);

    const canal = AndroidNotificationChannel(
      _idCanal,
      _nombreCanal,
      description: _descripcionCanal,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(canal);
  }

  Future<void> solicitarPermiso() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> mostrarAlerta(String titulo, String cuerpo) async {
    const detallesAndroid = AndroidNotificationDetails(
      _idCanal,
      _nombreCanal,
      channelDescription: _descripcionCanal,
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      onlyAlertOnce: true,
    );
    const detalles = NotificationDetails(android: detallesAndroid);

    await _plugin.show(
      _idNotificacionAlerta,
      titulo,
      cuerpo,
      detalles,
    );
  }
}
