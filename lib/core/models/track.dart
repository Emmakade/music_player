import 'package:hive/hive.dart';
import 'package:audio_service/audio_service.dart';

part 'track.g.dart';

/// Hive model for storing track metadata
@HiveType(typeId: 0)
class Track extends HiveObject {
  @HiveField(0)
  final String id; // file path or URI

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String artist;

  @HiveField(3)
  final String album;

  @HiveField(4)
  final String? artUri; // album artwork (path or URI)

  @HiveField(5)
  final int durationMs;

  @HiveField(6)
  final String path;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    this.artUri,
    required this.durationMs,
    required this.path,
  });

  /// Convenience getter
  Duration get duration => Duration(milliseconds: durationMs);

  /// Factory to convert plugin/DB map into Track
  factory Track.fromMap(Map<String, dynamic> map) {
    return Track(
      id: map['id']?.toString() ?? map['uri']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Unknown Title',
      artist: map['artist']?.toString() ?? 'Unknown Artist',
      album: map['album']?.toString() ?? 'Unknown Album',
      artUri: map['artUri']?.toString() ?? map['artwork']?.toString(),
      durationMs:
          int.tryParse(map['duration']?.toString() ?? '') ??
          int.tryParse(map['durationMs']?.toString() ?? '') ??
          0,
      path: map['path']?.toString() ?? map['uri']?.toString() ?? '',
    );
  }

  /// Convert Track to a MediaItem for audio_service
  MediaItem toMediaItem() {
    return MediaItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      artUri: artUri != null ? Uri.tryParse(artUri!) : null,
      extras: {'path': path},
    );
  }

  /// Create Track from MediaItem
  factory Track.fromMediaItem(MediaItem item) {
    return Track(
      id: item.id,
      title: item.title,
      artist: item.artist ?? 'Unknown Artist',
      album: item.album ?? 'Unknown Album',
      artUri: item.artUri?.toString(),
      durationMs: item.duration?.inMilliseconds ?? 0,
      path: item.extras?['path'] ?? item.id,
    );
  }
}
