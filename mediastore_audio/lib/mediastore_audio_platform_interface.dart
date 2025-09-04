import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mediastore_audio_method_channel.dart';

abstract class MediastoreAudioPlatform extends PlatformInterface {
  /// Constructs a MediastoreAudioPlatform.
  MediastoreAudioPlatform() : super(token: _token);

  static final Object _token = Object();

  static MediastoreAudioPlatform _instance = MethodChannelMediastoreAudio();

  /// The default instance of [MediastoreAudioPlatform] to use.
  ///
  /// Defaults to [MethodChannelMediastoreAudio].
  static MediastoreAudioPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MediastoreAudioPlatform] when
  /// they register themselves.
  static set instance(MediastoreAudioPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
