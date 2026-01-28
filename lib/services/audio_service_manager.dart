import 'package:audio_service/audio_service.dart';
import 'audio_handler.dart';

class AudioServiceManager {
  static AudioHandler? _handler;

  static Future<AudioHandler> init() async {
    if (_handler != null) return _handler!;

    _handler = await AudioService.init(
      builder: () => MyAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'offline_music_player',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'ic_launcher',
      ),
    );

    return _handler!;
  }
}
