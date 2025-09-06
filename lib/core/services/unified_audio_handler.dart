import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

import '../../core/models/track.dart';

/// A unified audio handler that bridges Hive `Track` models with `audio_service`.
class UnifiedAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  final _currentTrackController = StreamController<Track?>.broadcast();
  final _queueController = StreamController<List<Track>>.broadcast();

  List<Track> _queue = [];
  Track? _current;

  /// Local state
  List<Track> _queueTracks = [];
  final _isLoading = false;

  UnifiedAudioHandler() {
    // Sync player events to audio_service state
    _notifyAudioHandlerAboutPlaybackEvents();

    _player.playbackEventStream.listen((event) {
      playbackState.add(
        playbackState.value.copyWith(
          playing: _player.playing,
          updatePosition: _player.position,
          processingState: {
            ProcessingState.idle: AudioProcessingState.idle,
            ProcessingState.loading: AudioProcessingState.loading,
            ProcessingState.buffering: AudioProcessingState.buffering,
            ProcessingState.ready: AudioProcessingState.ready,
            ProcessingState.completed: AudioProcessingState.completed,
          }[_player.processingState]!,
        ),
      );
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index < _queue.length) {
        _current = _queue[index];
        _currentTrackController.add(_current);
      }
    });
  }

  /// Load a queue of tracks (replace existing queue)
  Future<void> loadQueue(List<Track> tracks) async {
    _queue = tracks;
    _queueTracks = tracks; // Keep them in sync
    final mediaItems = tracks.map((t) => t.toMediaItem()).toList();

    // Update queue
    queue.add(mediaItems);

    // Load into just_audio
    final audioSources = tracks
        .map((t) => AudioSource.uri(Uri.parse(t.path)))
        .toList();
    await _player.setAudioSource(
      ConcatenatingAudioSource(children: audioSources),
    );
  }

  /// Play a specific track by index
  @override
  Future<void> playMediaItem(MediaItem mediaItem) async {
    final index = queue.value.indexWhere((i) => i.id == mediaItem.id);
    if (index != -1) {
      await _player.seek(Duration.zero, index: index);
      await _player.play();
      updateMediaItem(mediaItem);
    }
  }

  /// QueueHandler methods
  @override
  Future<void> addQueueItem(MediaItem mediaItem) async {
    final track = Track.fromMediaItem(mediaItem);
    _queue.add(track);
    _queueTracks.add(track); // Keep them in sync
    final updatedQueue = [...queue.value, mediaItem];
    queue.add(updatedQueue);

    await (_player.audioSource as ConcatenatingAudioSource).add(
      AudioSource.uri(Uri.parse(track.path)),
    );
  }

  @override
  Future<void> removeQueueItem(MediaItem mediaItem) async {
    final index = queue.value.indexWhere((i) => i.id == mediaItem.id);
    if (index != -1) {
      _queue.removeAt(index);
      _queueTracks.removeAt(index); // Keep them in sync
      final updatedQueue = [...queue.value]..removeAt(index);
      queue.add(updatedQueue);

      await (_player.audioSource as ConcatenatingAudioSource).removeAt(index);
    }
  }

  // ✅ Streams PlayerBloc expects
  Stream<Track?> get currentTrackStream => _currentTrackController.stream;
  Stream<List<Track>> get queueStream => _queueController.stream;
  Stream<PlaybackState> get playbackStateStream => playbackState;

  // ✅ Manage queue
  Future<void> setQueue(List<Track> tracks) async {
    _queue = tracks;
    _queueTracks = tracks; // Keep them in sync
    _queueController.add(tracks);
    queue.add(tracks.map(_mapTrackToMediaItem).toList());

    // Stop current playback to avoid interruption
    await _player.stop();

    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(
          children: tracks
              .map((t) => AudioSource.uri(Uri.parse(t.path)))
              .toList(),
        ),
      );
    } catch (e) {
      print('Error setting audio source: $e');
    }
  }

  // ✅ Custom helper for PlayerBloc
  Future<void> playTrack(Track track) async {
    try {
      final index = _queue.indexWhere((t) => t.id == track.id);
      if (index != -1) {
        print('Playing track: ${track.title} at index: $index');

        // Wait for player to be ready to avoid interruption
        int attempts = 0;
        while ((_player.processingState == ProcessingState.loading ||
                _player.processingState == ProcessingState.buffering) &&
            attempts < 300) {
          await Future.delayed(Duration(milliseconds: 10));
          attempts++;
        }

        // Ensure we seek to the correct position
        await _player.seek(Duration.zero, index: index);

        // Wait a bit more if still loading
        attempts = 0;
        while (_player.processingState == ProcessingState.loading &&
            attempts < 100) {
          await Future.delayed(Duration(milliseconds: 10));
          attempts++;
        }

        await _player.play();

        // Update current track
        _current = track;
        _currentTrackController.add(_current);

        print('Successfully started playing: ${track.title}');
      } else {
        print('Track not found in queue: ${track.title}');
      }
    } catch (e) {
      print('Error playing track: $e');
      // Optionally retry or handle
    }
  }

  /// Playback controls
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    playbackState.add(
      playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  //TODO: Implement close(), in player Bloc or main.dart shutdown, this will be called
  Future<void> close() async {
    _currentTrackController.close();
    _queueController.close();
    await _player.dispose();
  }

  // === Internal Helpers ===

  void _notifyAudioHandlerAboutPlaybackEvents() {
    // Combine player streams into audio_service state
    Rx.combineLatest3<PlaybackEvent, bool, Duration?, PlaybackState>(
      _player.playbackEventStream,
      _player.playingStream,
      _player.durationStream,
      (event, playing, duration) {
        return playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (playing) MediaControl.pause else MediaControl.play,
            MediaControl.stop,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          androidCompactActionIndices: const [0, 1, 3],
          processingState: _transformProcessingState(_player.processingState),
          playing: playing,
          updatePosition: _player.position,
          bufferedPosition: _player.bufferedPosition,
          speed: _player.speed,
          queueIndex: _player.currentIndex,
        );
      },
    ).listen(playbackState.add);

    // Current media item
    _player.currentIndexStream.listen((index) {
      if (index != null && index < _queueTracks.length) {
        mediaItem.add(_queueTracks[index].toMediaItem());
      }
    });
  }

  AudioProcessingState _transformProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  // === Public streams for PlayerBloc ===

  /// Emits the current Track
  // Stream<Track?> get currentTrackStream => mediaItem.stream.map(
  //   (item) => item != null ? Track.fromMediaItem(item) : null,
  // );

  /// Emits the full queue as Tracks
  Stream<List<Track>> get queueTracksStream =>
      queue.stream.map((items) => items.map(Track.fromMediaItem).toList());

  /// Emits playing state
  Stream<bool> get isPlayingStream =>
      playbackState.stream.map((s) => s.playing);

  /// Emits current position
  Stream<Duration> get positionStream => _player.positionStream;

  MediaItem _mapTrackToMediaItem(Track t) {
    return MediaItem(
      id: t.id,
      title: t.title,
      artist: t.artist,
      album: t.album,
      duration: Duration(milliseconds: t.durationMs),
      artUri: t.artUri != null ? Uri.parse(t.artUri!) : null,
      extras: {'path': t.path},
    );
  }
}
