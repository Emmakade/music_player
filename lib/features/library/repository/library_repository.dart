import 'package:mediastore_audio/mediastore_audio.dart';
import '../../../core/models/track.dart';

/// Wrapper around your mediastore_audio plugin.
/// Ensures permissions and maps platform data -> Track model.
class LibraryRepository {
  final MediastoreAudio _mediastoreAudio;
  LibraryRepository() : _mediastoreAudio = MediastoreAudio();

  /// Ensure we have permission; if not, request it.
  /// Returns true if permission is granted.
  Future<bool> ensurePermission() async {
    try {
      final has = await MediastoreAudio.checkPermissions();
      if (has == true) return true;
      final requested = await MediastoreAudio.requestPermissions();
      return requested == true;
    } catch (e) {
      // plugin call failed, treat as no permission
      return false;
    }
  }

  /// Fetch tracks from mediastore_audio.listAudioFiles()
  /// Maps platform-specific keys to your Track model; resilient to variations.
  Future<List<Track>> fetchTracks() async {
    final ok = await ensurePermission();
    if (!ok) throw Exception('Permission not granted');

    final List<dynamic> raw = await _mediastoreAudio.getAudios();

    final List<Track> tracks = raw.map<Track>((dynamic item) {
      final Map<String, dynamic> map = (item is Map)
          ? Map<String, dynamic>.from(item)
          : <String, dynamic>{};

      print('raw audio item: $item');

      // flexible key extraction
      final String id = (map['id'] ?? map['_id'] ?? map['song_id'] ?? '')
          .toString();
      final String title =
          (map['title'] ??
                  map['display_name'] ??
                  map['name'] ??
                  'Unknown Title')
              .toString();
      final String artist =
          (map['artist'] ?? map['album_artist'] ?? 'Unknown Artist').toString();
      final String album = (map['album'] ?? map['albumName'] ?? 'Unknown Album')
          .toString();

      // duration may be milliseconds (Android) or seconds (iOS) or string
      int durationMs = 0;
      if (map.containsKey('duration')) {
        final d = map['duration'];
        if (d is int) {
          durationMs = d;
        } else if (d is double) {
          // assume seconds if small; convert to ms
          durationMs = (d < 1e6) ? (d * 1000).toInt() : d.toInt();
        } else {
          final parsed = int.tryParse(d.toString());
          if (parsed != null) {
            durationMs = parsed;
            // heuristic: if value looks like seconds (<= 86400) convert to ms
            if (durationMs <= 86400) durationMs = durationMs * 1000;
          }
        }
      } else if (map.containsKey('durationMs')) {
        durationMs = (map['durationMs'] is int)
            ? map['durationMs'] as int
            : int.tryParse(map['durationMs'].toString()) ?? 0;
      }

      // artwork / uri / path
      String? artwork;
      if (map.containsKey('artwork')) artwork = map['artwork']?.toString();
      artwork ??= map['albumArtUri']?.toString();
      artwork ??= map['album_art']?.toString();

      String? uri = map['uri']?.toString();
      uri ??= map['path']?.toString();
      uri ??= map['assetURL']?.toString();
      uri ??= map['data']?.toString();

      // Build Track — adapt this if your Track class has different fields
      return Track(
        id: id.isNotEmpty ? id : uri ?? title,
        title: title,
        artist: artist,
        album: album,
        artUri: artwork,
        durationMs: durationMs,
        path: uri ?? '',
        // if your Track model uses other fields, edit here
      );
    }).toList();

    return tracks;
  }

  /// Optional: fetch just file paths
  Future<List<String>> fetchAudioPaths() async {
    final ok = await ensurePermission();
    if (!ok) throw Exception('Permission not granted');
    final List<String> paths = await MediastoreAudio.listAudioFiles();
    return paths;
  }

  Future<bool> checkPermission() async {
    return await MediastoreAudio.checkPermissions();
  }

  Future<bool> requestPermission() async {
    return await MediastoreAudio.requestPermissions();
  }

  Future<List<Track>> getAllTracks() async {
    final ok = await ensurePermission();
    if (!ok) throw Exception("Permission not granted");

    final List<dynamic> raw = await _mediastoreAudio.getAudios();

    return raw.map<Track>((dynamic item) {
      final map = (item is Map) ? Map<String, dynamic>.from(item) : {};
      return Track(
        id: (map['id'] ?? map['uri'] ?? '').toString(),
        title: (map['title'] ?? map['name'] ?? 'Unknown Title').toString(),
        artist: (map['artist'] ?? 'Unknown Artist').toString(),
        album: (map['album'] ?? 'Unknown Album').toString(),
        artUri: map['artwork']?.toString(),
        durationMs: (map['duration'] is int) ? map['duration'] : 0,
        path: (map['path'] ?? map['uri'] ?? '').toString(),
      );
    }).toList();
  }
}
