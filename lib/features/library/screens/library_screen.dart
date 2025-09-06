import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:mediastore_audio/mediastore_audio.dart';
import 'package:music_player/features/library/bloc/library_event.dart';
import 'package:music_player/features/library/bloc/library_state.dart';
import 'package:music_player/features/library/repository/library_repository.dart';
import '../../../core/models/track.dart';
import '../../../core/route/route_names.dart';
import '../../../core/utils/format_duration.dart';
import '../../../core/utils/remove_file_extension.dart';
import '../../../shared/widgets/build_track_artwork.dart';
import '../../player/bloc/player_bloc.dart';
import '../../player/widgets/mini_player.dart';
import '../bloc/library_bloc.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mediastoreAudio = MediastoreAudio();
    // The trackBox is now opened in main.dart and passed to the bloc
    final trackBox = Hive.box<Track>('tracks');
    return BlocProvider(
      create: (_) =>
          LibraryBloc(mediastoreAudio, trackBox)..add(CheckPermissionEvent()),
      child: Scaffold(
        appBar: AppBar(title: const Text("Library")),
        body: BlocBuilder<LibraryBloc, LibraryState>(
          builder: (context, state) {
            if (state is LibraryPermissionDenied) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    context.read<LibraryBloc>().add(RequestPermissionEvent());
                  },
                  child: const Text("Grant Permission"),
                ),
              );
            } else if (state is LibraryLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is LibraryLoaded) {
              if (state.tracks.isEmpty) {
                return const Center(child: Text("No songs found"));
              }
              return ListView.builder(
                itemCount: state.tracks.length,
                itemBuilder: (context, index) {
                  final track = state.tracks[index];
                  return ListTile(
                    title: Text(
                      removeFileExtension(track.title),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    subtitle: Text(track.artist),
                    leading: buildTrackArtwork(track.artUri),
                    trailing: Text(formatDuration(track.durationMs)),
                    onTap: () {
                      context.read<PlayerBloc>().add(UpdateQueue(state.tracks));
                      context.read<PlayerBloc>().add(PlayTrack(track));

                      Navigator.pushNamed(
                        context,
                        RouteNames.nowPlaying,
                        arguments: {'track': track, 'tracks': state.tracks},
                      );
                    },
                  );
                },
              );
            } else if (state is LibraryError) {
              return Center(child: Text("Error: ${state.message}"));
            }
            return const SizedBox.shrink();
          },
        ),
        bottomNavigationBar: const Padding(
          padding: EdgeInsets.all(8.0),
          child: MiniPlayer(),
        ),
      ),
    );
  }
}
