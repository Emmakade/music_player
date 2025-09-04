import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediastore_audio/mediastore_audio_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelMediastoreAudio platform = MethodChannelMediastoreAudio();
  const MethodChannel channel = MethodChannel('mediastore_audio');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
