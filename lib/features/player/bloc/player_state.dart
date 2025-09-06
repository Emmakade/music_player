part of 'player_bloc.dart';

class PlayerState {
  final bool isPlaying;
  final Track? currentTrack;
  final Duration position;
  final List<Track> queue;

  PlayerState({
    this.isPlaying = false,
    this.currentTrack,
    this.position = Duration.zero,
    this.queue = const [],
  });

  PlayerState copyWith({
    bool? isPlaying,
    Track? currentTrack,
    Duration? position,
    List<Track>? queue,
  }) {
    return PlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      queue: queue ?? this.queue,
    );
  }
}

class PlayerInitial extends PlayerState {}

class PlayerLoaded extends PlayerState {
  PlayerLoaded({
    required super.isPlaying,
    required Track? current,
    required super.queue,
    super.position,
  }) : super(currentTrack: current);
}

class PlayerPlaying extends PlayerState {
  PlayerPlaying({
    required Track track,
    required super.position,
    required super.queue,
  }) : super(isPlaying: true, currentTrack: track);
}

class PlayerPaused extends PlayerState {
  PlayerPaused({
    required Track track,
    required super.position,
    required super.queue,
  }) : super(isPlaying: false, currentTrack: track);
}

class PlayerError extends PlayerState {
  final String message;
  PlayerError({
    required this.message,
    Track? track,
    super.position,
    super.queue,
  }) : super(isPlaying: false, currentTrack: track);
  // List<Object?> get props => [message, currentTrack, position, queue];
}
