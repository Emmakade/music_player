import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marquee/marquee.dart';
import 'package:music_player/core/models/track.dart';
import '../../../core/utils/format_duration.dart';
import '../../../core/utils/remove_file_extension.dart';
import '../../../shared/widgets/build_artwork.dart';
import '../bloc/player_bloc.dart';

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  final bool _queueInitialized = false;

  void _showQueueBottomSheet(BuildContext context, List<Track> queue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 6,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            Text(
              "Up Next",
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.white),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView.builder(
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final queueTrack = queue[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (queueTrack.artUri?.isNotEmpty ?? false)
                          ? NetworkImage(queueTrack.artUri!)
                          : null,
                      child:
                          (queueTrack.artUri == null ||
                              queueTrack.artUri!.isEmpty)
                          ? const Icon(Icons.music_note)
                          : null,
                    ),
                    title: Text(
                      removeFileExtension(queueTrack.title),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      queueTrack.artist,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<PlayerBloc>().add(PlayTrack(queueTrack));
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Now Playing'),
      ),
      body: BlocBuilder<PlayerBloc, PlayerState>(
        builder: (context, state) {
          final Track? currentTrack = state.currentTrack;
          final List<Track> queue = state.queue;

          if (currentTrack == null) {
            return const Center(
              child: Text(
                "No track selected",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final heroTag = 'artwork_${currentTrack.id}';
          final Duration position = state.position;
          final Duration duration = currentTrack.duration;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: buildArtwork(
                        currentTrack.artUri,
                        isCircular: false,
                        borderRadius: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                // Track title marquee
                SizedBox(
                  height: 30,
                  child: Marquee(
                    text: removeFileExtension(currentTrack.title),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    blankSpace: 20.0,
                    velocity: 40.0,
                    pauseAfterRound: const Duration(seconds: 2),
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  currentTrack.artist,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),

                // Progress bar
                Row(
                  children: [
                    Text(
                      formatDuration(position.inMilliseconds),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Expanded(
                      child: Slider(
                        value: duration.inSeconds > 0
                            ? position.inSeconds
                                  .clamp(0, duration.inSeconds)
                                  .toDouble()
                            : 0.0,
                        max: duration.inSeconds > 0
                            ? duration.inSeconds.toDouble()
                            : 1.0,
                        onChanged: (value) {
                          context.read<PlayerBloc>().add(
                            SeekPosition(Duration(seconds: value.toInt())),
                          );
                        },
                      ),
                    ),
                    Text(
                      formatDuration(duration.inMilliseconds),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 5),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 28),
                      onPressed: () {
                        context.read<PlayerBloc>().add(PrevTrack());
                      },
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<PlayerBloc>().add(PlayPause());
                      },
                      icon: Icon(
                        state.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                      label: Text(state.isPlaying ? 'Pause' : 'Play'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 28),
                      onPressed: () {
                        context.read<PlayerBloc>().add(NextTrack());
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Up Next',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () => _showQueueBottomSheet(context, queue),
                    icon: const Icon(Icons.queue_music, color: Colors.white),
                    label: const Text(
                      'Up Next',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
