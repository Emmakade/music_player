import 'package:flutter/material.dart';
import 'package:music_player/core/route/route_names.dart';
import 'package:music_player/features/player/widgets/now_playing.dart';

import '../../../core/models/track.dart';

class MusicListScreen extends StatelessWidget {
  final List<Track> tracks;
  const MusicListScreen({super.key, required this.tracks});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Music Library")),
      body: ListView.builder(
        itemCount: tracks.length,
        itemBuilder: (context, index) {
          final track = tracks[index];
          return ListTile(
            title: Text(track.title),
            subtitle: Text(track.artist ?? "Unknown"),
            onTap: () async {
              //await AudioPlayerHandler.instance.play(track);
              Navigator.pushNamed(
                context,
                RouteNames.nowPlaying,
                arguments: {'track': track, 'tracks': tracks},
              );
            },
          );
        },
      ),
    );
  }
}
