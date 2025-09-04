import 'package:flutter/material.dart';
import 'package:music_player/features/library/screens/library_screen.dart';
import 'package:music_player/features/player/widgets/music_list.dart';
import 'package:music_player/features/player/widgets/now_playing.dart';

import '../../features/splash/screen/splash_screen.dart';
import '../models/track.dart';
import 'route_names.dart';

final Map<String, WidgetBuilder> appRoutes = {
  RouteNames.splash: (context) => SplashScreen(),
  RouteNames.library: (context) => LibraryScreen(),
  RouteNames.nowPlaying: (context) {
    // final args =
    //     ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    // final track = args['track'] as Track?;
    // final tracks = args['tracks'] as List<Track>? ?? [];
    return NowPlayingScreen();
  },
  RouteNames.musicList: (context) => MusicListScreen(
    tracks: [
      Track(
        id: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
        title: "SoundHelix Song 1",
        artist: "SoundHelix",
        album: '',
        durationMs: 0,
        path: '',
      ),
      Track(
        id: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
        title: "SoundHelix Song 2",
        artist: "SoundHelix",
        album: '',
        durationMs: 0,
        path: '',
      ),
    ],
  ),
};
