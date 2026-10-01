import 'package:flutter/foundation.dart';

import '../../../core/auth/auth_session_lifecycle.dart';

/// Notifies notification UI surfaces to reload their data from the backend.
///
/// This carries no notification content and never changes the unread count.
class NotificationRefreshSignal extends ChangeNotifier
    implements AuthSessionLifecycle {
  NotificationRefreshSignal({
    DateTime Function()? clock,
    this.minimumInterval = const Duration(seconds: 2),
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Duration minimumInterval;

  DateTime? _lastRefreshAt;
  bool _authenticated = false;
  bool _disposed = false;

  bool get isAuthenticated => _authenticated && !_disposed;

  /// Returns true only when a refresh notification was emitted.
  bool requestRefresh() {
    if (!isAuthenticated) return false;

    final now = _clock();
    final lastRefresh = _lastRefreshAt;
    if (lastRefresh != null && now.difference(lastRefresh) < minimumInterval) {
      return false;
    }

    _lastRefreshAt = now;
    notifyListeners();
    return true;
  }

  void onAppResumed() => requestRefresh();

  @override
  void onAuthenticated() {
    _authenticated = true;
    _lastRefreshAt = null;
  }

  @override
  void onSigningOut() {
    _authenticated = false;
    _lastRefreshAt = null;
  }

  @override
  void onUnauthenticated() {
    _authenticated = false;
    _lastRefreshAt = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _authenticated = false;
    super.dispose();
  }
}
