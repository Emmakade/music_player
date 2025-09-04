import 'dart:async';
import 'package:flutter/services.dart';

class MediastoreAudio {
  static const MethodChannel _channel = MethodChannel('mediastore_audio');

  ///check for permission with mediastore_audio
  static Future<bool> checkPermissions() async {
    return await _channel.invokeMethod('checkPermissions');
  }

  ///request for permission with mediastore_audio
  static Future<bool> requestPermissions() async {
    return await _channel.invokeMethod('requestPermissions');
  }

  static Future<List<String>> listAudioFiles() async {
    final List<dynamic> files = await _channel.invokeMethod('listAudioFiles');
    return files.cast<String>();
  }

  /// Returns all audio metadata (via MediaStore on Android, MPMediaQuery on iOS)
  Future<List<dynamic>> getAudios() async {
    final result = await _channel.invokeMethod<List<dynamic>>('getAudios');
    return result ?? [];
  }

  /// Get platform version (for testing purposes)
  static Future<String?> getPlatformVersion() async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
