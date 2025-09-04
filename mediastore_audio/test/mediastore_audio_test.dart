import 'package:flutter_test/flutter_test.dart';
import 'package:mediastore_audio/mediastore_audio.dart';
import 'package:mediastore_audio/mediastore_audio_platform_interface.dart';
import 'package:mediastore_audio/mediastore_audio_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMediastoreAudioPlatform
    with MockPlatformInterfaceMixin
    implements MediastoreAudioPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final MediastoreAudioPlatform initialPlatform =
      MediastoreAudioPlatform.instance;

  test('$MethodChannelMediastoreAudio is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMediastoreAudio>());
  });

  test('getPlatformVersion', () async {
    //MediastoreAudio mediastoreAudioPlugin = MediastoreAudio();
    MockMediastoreAudioPlatform fakePlatform = MockMediastoreAudioPlatform();
    MediastoreAudioPlatform.instance = fakePlatform;

    expect(await MediastoreAudio.getPlatformVersion(), '42');
  });
}
