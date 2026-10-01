import 'dart:async';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../../core/auth/auth_session_lifecycle.dart';
import '../models/push_notification_destination.dart';

const ormanNotificationChannelId = 'orman_notificaciones';
const ormanNotificationChannelName = 'Notificaciones ORMAN';
const ormanNotificationChannelDescription =
    'Notificaciones de pagos y cuotas de ORMAN';

class PushNotificationMessage {
  const PushNotificationMessage({
    required this.data,
    this.messageId,
    this.title,
    this.body,
  });

  final Map<String, Object?> data;
  final String? messageId;
  final String? title;
  final String? body;
}

abstract interface class PushMessagingGateway {
  Stream<PushNotificationMessage> get foregroundMessages;

  Stream<PushNotificationMessage> get openedMessages;

  Future<PushNotificationMessage?> getInitialMessage();
}

class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  @override
  Stream<PushNotificationMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(_convert);

  @override
  Stream<PushNotificationMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp.map(_convert);

  @override
  Future<PushNotificationMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _convert(message);
  }

  static PushNotificationMessage _convert(RemoteMessage message) =>
      PushNotificationMessage(
        data: message.data,
        messageId: message.messageId,
        title: message.notification?.title,
        body: message.notification?.body,
      );
}

abstract interface class LocalNotificationGateway {
  Future<void> initialize({required ValueChanged<String?> onTap});

  Future<void> createAndroidChannel();

  Future<String?> getLaunchPayload();

  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  });

  Future<bool?> requestAndroidPermission();
}

class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  FlutterLocalNotificationGateway({
    FlutterLocalNotificationsPlugin? notifications,
    DeviceInfoPlugin? deviceInfo,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin(),
       _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final FlutterLocalNotificationsPlugin _notifications;
  final DeviceInfoPlugin _deviceInfo;

  @override
  Future<void> initialize({required ValueChanged<String?> onTap}) async {
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('orman_notification'),
      ),
      onDidReceiveNotificationResponse: (response) => onTap(response.payload),
    );
  }

  @override
  Future<void> createAndroidChannel() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        ormanNotificationChannelId,
        ormanNotificationChannelName,
        description: ormanNotificationChannelDescription,
        importance: Importance.defaultImportance,
        playSound: true,
        enableVibration: true,
      ),
    );
  }

  @override
  Future<String?> getLaunchPayload() async {
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) return null;
    return details?.notificationResponse?.payload;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    await _notifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          ormanNotificationChannelId,
          ormanNotificationChannelName,
          channelDescription: ormanNotificationChannelDescription,
          icon: 'orman_notification',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
          enableVibration: true,
        ),
      ),
      payload: payload,
    );
  }

  @override
  Future<bool?> requestAndroidPermission() async {
    final androidInfo = await _deviceInfo.androidInfo;
    if (androidInfo.version.sdkInt < 33) return true;
    return _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }
}

/// Displays foreground FCM messages and forwards notification taps.
class PushNotificationService implements AuthSessionLifecycle {
  PushNotificationService({
    required this.messaging,
    required this.localNotifications,
    this.onInboxRefresh,
  });

  final PushMessagingGateway messaging;
  final LocalNotificationGateway localNotifications;
  Future<void> Function()? onInboxRefresh;

  StreamSubscription<PushNotificationMessage>? _foregroundSubscription;
  StreamSubscription<PushNotificationMessage>? _openedSubscription;
  Future<void>? _startFuture;
  ValueChanged<PushNotificationDestination>? _onDestination;
  bool _initialized = false;
  bool _authenticated = false;
  bool _permissionRequestStarted = false;
  bool _disposed = false;
  final Set<String> _displayedKeys = <String>{};

  void setDestinationHandler(
    ValueChanged<PushNotificationDestination>? onDestination,
  ) {
    _onDestination = onDestination;
  }

  void setInboxRefreshHandler(Future<void> Function()? onInboxRefresh) {
    this.onInboxRefresh = onInboxRefresh;
  }

  Future<void> start() => _startFuture ??= _start();

  Future<void> _start() async {
    if (_disposed) return;
    try {
      await localNotifications.initialize(onTap: handleLocalNotificationTap);
      await localNotifications.createAndroidChannel();
      _initialized = true;
    } on Object {
      // Notification setup is best-effort and must not block app startup.
    }

    try {
      _foregroundSubscription = messaging.foregroundMessages.listen(
        (message) => unawaited(handleForegroundMessage(message)),
        onError: (Object _) {
          // A stream error must not escape into app startup or auth flows.
        },
      );
      _openedSubscription = messaging.openedMessages.listen(
        handleOpenedMessage,
        onError: (Object _) {
          // A stream error must not escape into app startup or auth flows.
        },
      );
    } on Object {
      // FCM listeners are optional and must not block app startup.
    }

    if (_initialized) {
      try {
        handleLocalNotificationTap(await localNotifications.getLaunchPayload());
      } on Object {
        // An unavailable launch payload only means there is no local tap to route.
      }
    }

    try {
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) handleOpenedMessage(initialMessage);
    } on Object {
      // Cold-start push navigation is optional; keep normal startup available.
    }

    _requestPermissionIfReady();
  }

  Future<void> handleForegroundMessage(PushNotificationMessage message) async {
    final destination = PushNotificationDestination.fromData(
      message.data,
      messageId: message.messageId,
    );
    if (destination != null) {
      if (!_displayedKeys.add(destination.deduplicationKey)) return;
      _trimKeys(_displayedKeys);
    }

    if (destination == null || !_initialized || _disposed) {
      await _refreshInboxBestEffort();
      return;
    }

    final title = _nonEmpty(message.title) ?? 'ORMAN';
    final body = _nonEmpty(message.body) ?? destination.type.fallbackBody;
    try {
      await localNotifications.show(
        id: _notificationId(destination),
        title: title,
        body: body,
        payload: jsonEncode(destination.toData()),
      );
    } on Object {
      // A local alert failure must not block the REST inbox refresh.
    }
    await _refreshInboxBestEffort();
  }

  void handleOpenedMessage(PushNotificationMessage message) {
    final destination = PushNotificationDestination.fromData(
      message.data,
      messageId: message.messageId,
    );
    if (destination != null) _onDestination?.call(destination);
  }

  void handleLocalNotificationTap(String? payload) {
    if (payload == null || payload.isEmpty || _disposed) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      final data = decoded.map<String, Object?>(
        (key, value) => MapEntry(key.toString(), value),
      );
      final destination = PushNotificationDestination.fromData(data);
      if (destination != null) _onDestination?.call(destination);
    } on Object {
      // Ignore malformed or stale local notification payloads.
    }
  }

  @override
  void onAuthenticated() {
    _authenticated = true;
    _requestPermissionIfReady();
  }

  @override
  void onSigningOut() {
    _authenticated = false;
  }

  @override
  void onUnauthenticated() {
    _authenticated = false;
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _authenticated = false;
    await _foregroundSubscription?.cancel();
    await _openedSubscription?.cancel();
    _foregroundSubscription = null;
    _openedSubscription = null;
  }

  void _requestPermissionIfReady() {
    if (!_initialized ||
        !_authenticated ||
        _permissionRequestStarted ||
        _disposed) {
      return;
    }
    _permissionRequestStarted = true;
    unawaited(_requestPermission());
  }

  Future<void> _requestPermission() async {
    try {
      await localNotifications.requestAndroidPermission();
    } on Object {
      // Permission denial or platform errors must not affect authentication.
    }
  }

  Future<void> _refreshInboxBestEffort() async {
    if (!_authenticated || _disposed) return;
    try {
      await onInboxRefresh?.call();
    } on Object {
      // REST refresh failures must not affect FCM delivery or local alerts.
    }
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static int _notificationId(PushNotificationDestination destination) {
    final code = destination.notificationCode;
    if (code != null && code <= 0x7fffffff) return code;
    return destination.deduplicationKey.hashCode & 0x7fffffff;
  }

  static void _trimKeys(Set<String> keys) {
    if (keys.length > 100) keys.remove(keys.first);
  }
}
