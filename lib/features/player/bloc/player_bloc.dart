import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

import '../../../core/models/track.dart';
import '../../../core/services/unified_audio_handler.dart';

part 'player_event.dart';
part 'player_state.dart';

class PlayerBloc extends Bloc<PlayerEvent, PlayerState> {
  final UnifiedAudioHandler _audioHandler;
  final Box<Track> _prefsBox;
  final Box _stringPrefsBox;

  StreamSubscription? _playingSub;
  StreamSubscription? _trackSub;
  StreamSubscription? _queueSub;
  StreamSubscription? _positionSub;

  List<Track> _queue = [];
  Track? _current;
  List<Track> _libraryTracks = [];
  List<String> _pendingQueueIds = [];

  PlayerBloc(this._audioHandler, this._prefsBox, this._stringPrefsBox)
    : super(PlayerInitial()) {
    print(
      'PlayerBloc initialized with boxes: ${_prefsBox.name}, ${_stringPrefsBox.name}',
    );

    on<PlayTrack>(_onPlayTrack);
    on<PausePlayback>(_onPause);
    on<ResumePlayback>(_onResume);
    on<NextTrack>(_onNext);
    on<PrevTrack>(_onPrev);
    on<UpdateQueue>(_onUpdateQueue);
    on<UpdatePlaybackState>(_onUpdatePlaybackState);
    on<UpdateCurrentTrack>(_onUpdateCurrentTrack);
    on<SyncLibraryTracks>(_onSyncLibraryTracks);
    on<UpdatePlaybackPosition>(_onUpdatePlaybackPosition);

    // 👇 Add new handlers
    on<PlayPause>(_onPlayPause);
    on<SeekPosition>(_onSeekPosition);

    // listen to handler streams
    _playingSub = _audioHandler.playbackStateStream.listen((playback) {
      add(UpdatePlaybackState(playback.playing));
    });

    _trackSub = _audioHandler.currentTrackStream.listen((track) {
      _current = track;
      _saveCurrentTrack(track);
      add(UpdateCurrentTrack(track));
    });

    _queueSub = _audioHandler.queueStream.listen((queue) {
      _queue = queue;
      _saveQueue(queue);
      add(UpdateQueue(queue));
    });

    _positionSub = _audioHandler.positionStream.listen((pos) {
      _savePosition(pos);
      add(UpdatePlaybackPosition(pos)); // <-- tell Bloc/UI
    });

    // Restore from memory
    _restoreFromHive();
  }

  Future<void> _onPlayTrack(PlayTrack event, Emitter<PlayerState> emit) async {
    await _audioHandler.playTrack(event.track);

    _current = event.track;
    emit(PlayerLoaded(current: _current, queue: _queue, isPlaying: true));
  }

  Future<void> _onPause(PausePlayback event, Emitter<PlayerState> emit) async {
    await _audioHandler.pause();
    if (state is PlayerLoaded) {
      final currentState = state as PlayerLoaded;
      emit(currentState.copyWith(isPlaying: false));
    }
  }

  Future<void> _onResume(
    ResumePlayback event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioHandler.play();
    if (state is PlayerLoaded) {
      final currentState = state as PlayerLoaded;
      emit(currentState.copyWith(isPlaying: true));
    }
  }

  Future<void> _onNext(NextTrack event, Emitter<PlayerState> emit) async {
    await _audioHandler.skipToNext();
  }

  Future<void> _onPrev(PrevTrack event, Emitter<PlayerState> emit) async {
    await _audioHandler.skipToPrevious();
  }

  Future<void> _onPlayPause(PlayPause event, Emitter<PlayerState> emit) async {
    final isCurrentlyPlaying =
        state is PlayerLoaded && (state as PlayerLoaded).isPlaying;

    if (isCurrentlyPlaying) {
      await _audioHandler.pause();
      emit((state as PlayerLoaded).copyWith(isPlaying: false));
    } else {
      await _audioHandler.play();
      emit((state as PlayerLoaded).copyWith(isPlaying: true));
    }
  }

  Future<void> _onSeekPosition(
    SeekPosition event,
    Emitter<PlayerState> emit,
  ) async {
    await _audioHandler.seek(event.position);
    if (state is PlayerLoaded) {
      final currentState = state as PlayerLoaded;
      emit(currentState.copyWith(position: event.position));
    }
  }

  Future<void> _onUpdateQueue(
    UpdateQueue event,
    Emitter<PlayerState> emit,
  ) async {
    emit(
      PlayerLoaded(
        current: _current,
        queue: event.queue,
        isPlaying: state is PlayerLoaded
            ? (state as PlayerLoaded).isPlaying
            : false,
      ),
    );
  }

  Future<void> _onUpdatePlaybackState(
    UpdatePlaybackState event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is PlayerLoaded) {
      final currentState = state as PlayerLoaded;
      emit(currentState.copyWith(isPlaying: event.isPlaying));
    }
  }

  Future<void> _onUpdateCurrentTrack(
    UpdateCurrentTrack event,
    Emitter<PlayerState> emit,
  ) async {
    _current = event.track;
    emit(
      PlayerLoaded(
        current: event.track,
        queue: _queue,
        isPlaying: state is PlayerLoaded
            ? (state as PlayerLoaded).isPlaying
            : false,
      ),
    );
  }

  // Persistence
  void _saveCurrentTrack(Track? track) {
    if (track != null && _prefsBox.isOpen) {
      try {
        _prefsBox.put('currentTrack', track);
      } catch (e) {
        print('Error saving current track: $e');
      }
    }
  }

  void _saveQueue(List<Track> queue) {
    if (_stringPrefsBox.isOpen) {
      try {
        final trackIds = queue.map((t) => t.id).toList();
        _stringPrefsBox.put('queueIds', trackIds);
      } catch (e) {
        print('Error saving queue: $e');
      }
    }
  }

  void _savePosition(Duration position) {
    if (_stringPrefsBox.isOpen) {
      try {
        _stringPrefsBox.put('positionMs', position.inMilliseconds);
      } catch (e) {
        print('Error saving position: $e');
      }
    }
  }

  void _restoreFromHive() {
    if (!_prefsBox.isOpen) return;

    try {
      final savedTrack = _prefsBox.get('currentTrack');
      if (savedTrack != null) {
        _current = savedTrack;
        add(UpdateCurrentTrack(savedTrack));
      }

      final queueIds = _stringPrefsBox.get('queueIds', defaultValue: []);
      if (queueIds is List) {
        _pendingQueueIds = List<String>.from(queueIds);
      }

      final savedPosMs = _stringPrefsBox.get('positionMs', defaultValue: 0);
      if (savedPosMs is int && savedPosMs > 0) {
        final restored = Duration(milliseconds: savedPosMs);
        final rewind = Duration(seconds: 3);
        final adjusted = restored > rewind ? restored - rewind : Duration.zero;
        add(UpdatePlaybackPosition(adjusted));
      }
    } catch (e) {
      print('Error restoring from Hive: $e');
    }
  }

  Future<void> _onSyncLibraryTracks(
    SyncLibraryTracks event,
    Emitter<PlayerState> emit,
  ) async {
    _libraryTracks = event.libraryTracks;

    if (_pendingQueueIds.isNotEmpty) {
      final restoredQueue = _libraryTracks
          .where((track) => _pendingQueueIds.contains(track.id))
          .toList();

      if (restoredQueue.isNotEmpty) {
        _queue = restoredQueue;
        add(UpdateQueue(restoredQueue));
      }
    }

    if (_current != null) {
      emit(PlayerLoaded(current: _current!, queue: _queue, isPlaying: false));
    }
  }

  Future<void> _onUpdatePlaybackPosition(
    UpdatePlaybackPosition event,
    Emitter<PlayerState> emit,
  ) async {
    if (state is PlayerLoaded) {
      final currentState = state as PlayerLoaded;
      emit(currentState.copyWith(position: event.position));
    }
  }

  @override
  Future<void> close() {
    _playingSub?.cancel();
    _trackSub?.cancel();
    _queueSub?.cancel();
    _positionSub?.cancel();
    return super.close();
  }
}
