import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mediastore_audio_platform_interface.dart';

/// An implementation of [MediastoreAudioPlatform] that uses method channels.
class MethodChannelMediastoreAudio extends MediastoreAudioPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mediastore_audio');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
