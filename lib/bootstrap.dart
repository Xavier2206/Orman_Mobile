import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app/app.dart';
import 'app/configuration/app_config.dart';
import 'core/auth/auth_session_factory.dart';
import 'features/notifications/data/fcm_fid_registration_bridge.dart';
import 'features/notifications/data/notification_refresh_signal.dart';
import 'features/notifications/data/push_installation_service.dart';
import 'features/notifications/data/push_notification_service.dart';

/// Inicialización y arranque global de la aplicación ORMAN.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final notificationRefreshSignal = NotificationRefreshSignal();
  final installationIds = await _initializeFirebaseForAndroid();
  final pushNotificationService = installationIds == null
      ? null
      : PushNotificationService(
          messaging: FirebasePushMessagingGateway(
            messaging: FirebaseMessaging.instance,
          ),
          localNotifications: FlutterLocalNotificationGateway(
            notifications: FlutterLocalNotificationsPlugin(),
          ),
          onInboxRefresh: () async {
            notificationRefreshSignal.requestRefresh();
          },
        );
  final dependencies = createApplicationDependencies(
    config,
    installationIds: installationIds,
    fidRegistrationBridge: installationIds == null
        ? null
        : MethodChannelFcmFidRegistrationBridge(),
  );
  runApp(
    OrmanApp(
      sessionManager: dependencies.sessionManager,
      apiClient: dependencies.apiClient,
      pushInstallationService: dependencies.pushInstallationService,
      pushNotificationService: pushNotificationService,
      notificationRefreshSignal: notificationRefreshSignal,
    ),
  );
}

Future<InstallationIdSource?> _initializeFirebaseForAndroid() async {
  if (defaultTargetPlatform != TargetPlatform.android) return null;
  try {
    await Firebase.initializeApp();
    return FirebaseInstallationIdSource();
  } on Object {
    // Firebase push is optional; a startup failure leaves the app usable.
    return null;
  }
}
