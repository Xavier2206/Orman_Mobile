import 'package:flutter/services.dart';

abstract interface class FcmFidRegistrationBridge {
  Future<String> registerFid();
}

class MethodChannelFcmFidRegistrationBridge
    implements FcmFidRegistrationBridge {
  MethodChannelFcmFidRegistrationBridge();

  static const channelName = 'com.orman.orman/fcm_fid_registration';
  static const methodName = 'registerFid';
  static const MethodChannel _channel = MethodChannel(channelName);

  @override
  Future<String> registerFid() async {
    final fid = await _channel.invokeMethod<String>(methodName);
    if (!isValidFirebaseInstallationId(fid)) {
      throw StateError('Firebase returned an invalid installation ID.');
    }
    return fid!;
  }
}

bool isValidFirebaseInstallationId(String? fid) =>
    fid != null && RegExp(r'^[cdef][A-Za-z0-9_-]{21}$').hasMatch(fid);
