import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../core/auth/auth_session_lifecycle.dart';
import '../../../core/network/api_client.dart';
import '../models/push_notification_destination.dart';
import 'notification_api.dart';

typedef InstallmentNavigation = bool Function(int installmentCode);
typedef NotificationReadMarker = Future<void> Function(int notificationCode);

/// Holds notification destinations until the mobile session and navigator exist.
class NotificationNavigationCoordinator implements AuthSessionLifecycle {
  NotificationNavigationCoordinator({
    required ApiClient apiClient,
    required this.navigateToInstallment,
    NotificationReadMarker? markRead,
  }) : _markRead =
           markRead ??
           ((code) async {
             await NotificationApi(apiClient).markRead(code);
           });

  final InstallmentNavigation navigateToInstallment;
  final NotificationReadMarker _markRead;
  final Set<String> _handledKeys = <String>{};

  PushNotificationDestination? _pendingDestination;
  bool _authenticated = false;
  bool _navigationScheduled = false;
  bool _disposed = false;
  int _sessionGeneration = 0;

  bool get hasPendingDestination => _pendingDestination != null;

  void receive(PushNotificationDestination destination) {
    if (_disposed || _handledKeys.contains(destination.deduplicationKey)) {
      return;
    }
    if (_pendingDestination?.deduplicationKey == destination.deduplicationKey) {
      return;
    }
    _pendingDestination = destination;
    _scheduleNavigationIfReady();
  }

  @override
  void onAuthenticated() {
    _authenticated = true;
    _scheduleNavigationIfReady();
  }

  @override
  void onSigningOut() {
    _authenticated = false;
    _sessionGeneration++;
    _pendingDestination = null;
  }

  @override
  void onUnauthenticated() {
    if (_authenticated) {
      _sessionGeneration++;
      _pendingDestination = null;
    }
    _authenticated = false;
  }

  void dispose() {
    _disposed = true;
    _authenticated = false;
    _pendingDestination = null;
  }

  void _scheduleNavigationIfReady() {
    if (!_authenticated ||
        _pendingDestination == null ||
        _navigationScheduled ||
        _disposed) {
      return;
    }
    _navigationScheduled = true;
    final sessionGeneration = _sessionGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationScheduled = false;
      if (!_authenticated ||
          _disposed ||
          sessionGeneration != _sessionGeneration) {
        return;
      }

      final destination = _pendingDestination;
      if (destination == null) return;
      try {
        if (!navigateToInstallment(destination.installmentCode)) return;
      } on Object {
        // Keep the destination pending so a later frame can try again.
        return;
      }

      _pendingDestination = null;
      _handledKeys.add(destination.deduplicationKey);
      if (_handledKeys.length > 100) _handledKeys.remove(_handledKeys.first);
      final notificationCode = destination.notificationCode;
      if (notificationCode != null) {
        unawaited(_markReadBestEffort(notificationCode));
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _markReadBestEffort(int notificationCode) async {
    try {
      await _markRead(notificationCode);
    } on Object {
      // Opening the requested installment must not depend on marking read.
    }
  }
}
