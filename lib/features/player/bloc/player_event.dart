part of 'player_bloc.dart';

abstract class PlayerEvent {}

class LoadQueue extends PlayerEvent {
  final List<Track> tracks;
  LoadQueue(this.tracks);
}

class PlayTrack extends PlayerEvent {
  final Track track;
  PlayTrack(this.track);
}

class PlayPause extends PlayerEvent {}

class NextTrack extends PlayerEvent {}

class PreviousTrack extends PlayerEvent {}

class SeekPosition extends PlayerEvent {
  final Duration position;
  SeekPosition(this.position);
}

//class PlayTrack extends PlayerEvent { final Track track; }
class PausePlayback extends PlayerEvent {}

class ResumePlayback extends PlayerEvent {}

class PrevTrack extends PlayerEvent {}

class UpdateQueue extends PlayerEvent {
  final List<Track> queue;
  UpdateQueue(this.queue);
}

class UpdateCurrentTrack extends PlayerEvent {
  final Track? track;
  UpdateCurrentTrack(this.track);
}

class UpdatePlaybackState extends PlayerEvent {
  final bool isPlaying;
  UpdatePlaybackState(this.isPlaying);
}

class SyncLibraryTracks extends PlayerEvent {
  final List<Track> libraryTracks;
  SyncLibraryTracks(this.libraryTracks);
}

class UpdatePlaybackPosition extends PlayerEvent {
  final Duration position;
  UpdatePlaybackPosition(this.position);
}
