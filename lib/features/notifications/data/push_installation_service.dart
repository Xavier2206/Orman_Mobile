import 'dart:async';

import 'package:firebase_app_installations/firebase_app_installations.dart';

import '../../../core/auth/auth_session_lifecycle.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'fcm_fid_registration_bridge.dart';

abstract interface class InstallationIdSource {
  Stream<String> get onIdChange;
}

class FirebaseInstallationIdSource implements InstallationIdSource {
  FirebaseInstallationIdSource({FirebaseInstallations? installations})
    : _installations = installations ?? FirebaseInstallations.instance;

  final FirebaseInstallations _installations;

  @override
  Stream<String> get onIdChange => _installations.onIdChange;
}

/// Best-effort FID registration, gated by a valid MOBILE session.
class PushInstallationService implements AuthSessionLifecycle {
  PushInstallationService({
    required this.apiClient,
    required this.installationIds,
    required this.registrationBridge,
  });

  final ApiClient apiClient;
  final InstallationIdSource installationIds;
  final FcmFidRegistrationBridge registrationBridge;

  StreamSubscription<String>? _subscription;
  bool _started = false;
  bool _disposed = false;
  bool _authenticated = false;
  bool _syncing = false;
  bool _syncQueued = false;
  int _sessionGeneration = 0;

  void start() {
    if (_started || _disposed) return;
    _started = true;
    try {
      _subscription = installationIds.onIdChange.listen(
        _onInstallationIdChanged,
        onError: (Object _) {
          // Installation ID change events are best-effort.
        },
      );
    } on Object {
      // Firebase installation updates must not block app startup.
    }
  }

  @override
  void onAuthenticated() {
    if (_disposed) return;
    _authenticated = true;
    _queueSync();
  }

  @override
  void onSigningOut() {
    _stopForUnauthenticatedSession();
  }

  @override
  void onUnauthenticated() {
    _stopForUnauthenticatedSession();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _authenticated = false;
    _sessionGeneration++;
    _syncQueued = false;
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onInstallationIdChanged(String _) {
    if (!_authenticated || _disposed) return;
    _queueSync();
  }

  void _queueSync() {
    if (!_authenticated || _disposed) return;
    _syncQueued = true;
    if (!_syncing) unawaited(_drainSyncQueue(_sessionGeneration));
  }

  Future<void> _drainSyncQueue(int generation) async {
    _syncing = true;
    try {
      while (_syncQueued && _isCurrentSession(generation)) {
        _syncQueued = false;
        try {
          final installationId = await registrationBridge.registerFid();
          if (!_isCurrentSession(generation)) return;
          if (!isValidFirebaseInstallationId(installationId)) {
            throw StateError('Firebase returned an invalid installation ID.');
          }
          await apiClient.putEmpty(
            ApiEndpoints.pushInstallation,
            data: {'installationId': installationId, 'platform': 'ANDROID'},
          );
        } on Object {
          // A FID change queued during a failed sync gets one best-effort
          // attempt. The same request is not retried in a loop.
          if (!_syncQueued) {
            break;
          }
        }
      }
    } finally {
      _syncing = false;
      if (_syncQueued && _authenticated && !_disposed) {
        unawaited(_drainSyncQueue(_sessionGeneration));
      }
    }
  }

  bool _isCurrentSession(int generation) =>
      !_disposed && _authenticated && generation == _sessionGeneration;

  void _stopForUnauthenticatedSession() {
    _authenticated = false;
    _sessionGeneration++;
    _syncQueued = false;
  }
}
