class SensorData {
  final double temperatura;
  final String estado;
  final String mensaje;
  final DateTime timestamp;

  const SensorData({
    required this.temperatura,
    required this.estado,
    required this.mensaje,
    required this.timestamp,
  });

  bool get esAlerta => estado == 'ALERTA_MIN' || estado == 'ALERTA_MAX';
}
