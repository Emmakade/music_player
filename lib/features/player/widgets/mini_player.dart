import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_player/core/route/route_names.dart';
import '../../../core/utils/remove_file_extension.dart';
import '../bloc/player_bloc.dart';

// Usage example:
//TODO: I will apply all these Usage example changes here

// final playerBloc = PlayerBloc(audioHandler);

// // Load songs
// context.read<PlayerBloc>().add(LoadQueue(myTracks));

// // Play one
// context.read<PlayerBloc>().add(PlayTrack(myTracks.first));

// // Toggle play/pause
// context.read<PlayerBloc>().add(PlayPause());

// // Seek
// context.read<PlayerBloc>().add(SeekPosition(Duration(seconds: 42)));

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, PlayerState>(
      builder: (context, state) {
        if (state is! PlayerPlaying && state is! PlayerPaused) {
          return const SizedBox.shrink();
        }
        final track = state is PlayerPlaying
            ? state.currentTrack
            : (state as PlayerPaused).currentTrack;
        final heroTag = 'artwork_${track!.id}';

        //TODO: add mini seek bar or progress indicator at bottom of mini player
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushNamed(
              context,
              RouteNames.nowPlaying,
              arguments: {
                'track': track,
                'tracks': [track],
              },
            ),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child:
                            (track.artUri != null && track.artUri!.isNotEmpty)
                            ? Image.network(track.artUri!, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.shade800,
                                child: const Icon(Icons.music_note),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${removeFileExtension(track.title)} • ${track.artist}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      state is PlayerPlaying ? Icons.pause : Icons.play_arrow,
                    ),
                    onPressed: () {
                      context.read<PlayerBloc>().add(PlayPause());
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
