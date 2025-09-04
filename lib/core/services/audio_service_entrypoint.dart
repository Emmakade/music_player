import 'package:audio_service/audio_service.dart';
import 'unified_audio_handler.dart';

@pragma('vm:entry-point')
Future<AudioHandler> audioServiceEntrypoint() async {
  //AudioServiceBackground.run(() => UnifiedAudioHandler());
  return AudioService.init(
    builder: () => UnifiedAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music_player.channel.audio',
      androidNotificationChannelName: 'Music Playback',
      androidNotificationOngoing: true,
    ),
  );
}
