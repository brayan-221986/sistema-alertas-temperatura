class SensorData {
  final double temperatura;
  final String estado;
  final DateTime timestamp;

  const SensorData({
    required this.temperatura,
    required this.estado,
    required this.timestamp,
  });

  bool get esAlerta => estado == 'ALERTA';
}
