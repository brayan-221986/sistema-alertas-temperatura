import 'package:audioplayers/audioplayers.dart';

class AlertSoundService {
  final AudioPlayer _reproductor = AudioPlayer();
  bool _sonandoActualmente = false;

  AlertSoundService() {
    _reproductor.setReleaseMode(ReleaseMode.loop);
  }

  Future<void> activar() async {
    if (_sonandoActualmente) return;
    _sonandoActualmente = true;
    await _reproductor.play(AssetSource('sounds/alerta.mp3'));
  }

  Future<void> detener() async {
    if (!_sonandoActualmente) return;
    _sonandoActualmente = false;
    await _reproductor.stop();
  }

  void liberar() => _reproductor.dispose();
}
