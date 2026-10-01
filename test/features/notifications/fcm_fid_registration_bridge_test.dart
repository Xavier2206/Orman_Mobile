import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/features/notifications/data/fcm_fid_registration_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    MethodChannelFcmFidRegistrationBridge.channelName,
  );
  final bridge = MethodChannelFcmFidRegistrationBridge();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('invokes only registerFid and returns the native FID', () async {
    const fid = 'caaaaaaaaaaaaaaaaaaaaa';
    MethodCall? receivedCall;
    messenger.setMockMethodCallHandler(channel, (call) async {
      receivedCall = call;
      return fid;
    });

    expect(await bridge.registerFid(), fid);
    expect(receivedCall?.method, 'registerFid');
    expect(receivedCall?.arguments, isNull);
    expect(
      MethodChannelFcmFidRegistrationBridge.channelName,
      'com.orman.orman/fcm_fid_registration',
    );
  });

  test('propagates controlled native registration errors', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'fcm_registration_failed',
        message: 'Firebase Messaging registration failed.',
      );
    });

    await expectLater(
      bridge.registerFid(),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'fcm_registration_failed',
        ),
      ),
    );
  });

  test('rejects an empty or malformed native FID', () async {
    for (final fid in <String?>[null, '', 'not-a-fid']) {
      messenger.setMockMethodCallHandler(channel, (call) async => fid);

      await expectLater(bridge.registerFid(), throwsStateError);
    }
  });
}
