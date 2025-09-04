import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mediastore_audio/mediastore_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:music_player/core/models/track.dart';

import 'core/route/app_routes.dart';
import 'core/route/route_names.dart';
import 'features/library/bloc/library_bloc.dart';
import 'features/player/bloc/player_bloc.dart';
import 'shared/theme/theme.dart';
import 'core/services/unified_audio_handler.dart';

late final UnifiedAudioHandler audioHandler;
late final Box<Track> _prefsBox;
late final Box _stringPrefsBox;
late final MediastoreAudio _mediastoreAudio;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Hive initialization
  await Hive.initFlutter();
  Hive.registerAdapter(TrackAdapter());

  try {
    _prefsBox = await Hive.openBox<Track>('tracks');
    _stringPrefsBox = await Hive.openBox('stringPrefs');
    print('Hive boxes opened successfully');
  } catch (e) {
    print('Error opening Hive boxes: $e');
    rethrow;
  }

  // ✅ MediastoreAudio initialization
  _mediastoreAudio = MediastoreAudio();

  // ✅ AudioHandler initialization
  try {
    audioHandler = await AudioService.init(
      builder: () => UnifiedAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelId: 'com.example.music_player.channel.audio',
        androidNotificationChannelName: 'Music Playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (e) {
    print('Error initializing AudioService: $e');
    // Fallback: create handler without AudioService
    audioHandler = UnifiedAudioHandler();
  }

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (ctx) => LibraryBloc(_mediastoreAudio, _prefsBox)),
        BlocProvider(
          create: (_) => PlayerBloc(audioHandler, _prefsBox, _stringPrefsBox),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Music Player',
        theme: appTheme,
        initialRoute: RouteNames.library,
        routes: appRoutes,
      ),
    );
  }
}
