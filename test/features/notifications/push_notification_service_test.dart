import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/core/auth/auth_session_events.dart';
import 'package:orman/core/auth/auth_state.dart';
import 'package:orman/core/auth/session_manager.dart';
import 'package:orman/features/notifications/data/push_notification_service.dart';
import 'package:orman/features/notifications/models/push_notification_destination.dart';

import '../../support/fake_auth_session_service.dart';

void main() {
  late FakeMessagingGateway messaging;
  late FakeLocalNotificationGateway localNotifications;
  late PushNotificationService service;
  var refreshRequests = 0;
  final destinations = <PushNotificationDestination>[];

  setUp(() {
    messaging = FakeMessagingGateway();
    localNotifications = FakeLocalNotificationGateway();
    refreshRequests = 0;
    service = PushNotificationService(
      messaging: messaging,
      localNotifications: localNotifications,
      onInboxRefresh: () async {
        refreshRequests++;
      },
    )..setDestinationHandler(destinations.add);
    destinations.clear();
  });

  tearDown(() async {
    await service.dispose();
    await messaging.close();
  });

  for (final type in OrmanPushNotificationType.values) {
    test('foreground ${type.value} displays one local notification', () async {
      await service.start();
      await service.handleForegroundMessage(_message(type));

      expect(localNotifications.shown, hasLength(1));
      expect(localNotifications.shown.single.title, 'Pago ORMAN');
      expect(
        localNotifications.shown.single.body,
        'Consulta la cuota en ORMAN.',
      );
      expect(localNotifications.channelCreated, isTrue);
    });
  }

  test('foreground uses safe fallback text and deduplicates', () async {
    await service.start();
    service.onAuthenticated();
    final message = _message(
      OrmanPushNotificationType.installmentOverdue,
      notificationCode: 75,
      notificationTitle: null,
      notificationBody: null,
    );

    await service.handleForegroundMessage(message);
    await service.handleForegroundMessage(message);

    expect(localNotifications.shown, hasLength(1));
    expect(refreshRequests, 1);
    expect(localNotifications.shown.single.title, 'ORMAN');
    expect(localNotifications.shown.single.body, 'Tienes una cuota vencida.');
  });

  test(
    'foreground message refreshes the inbox without adding an entity',
    () async {
      await service.start();
      service.onAuthenticated();

      await service.handleForegroundMessage(
        _message(OrmanPushNotificationType.paymentConfirmed),
      );

      expect(refreshRequests, 1);
      expect(localNotifications.shown, hasLength(1));
    },
  );

  test('REST refresh failure does not break the foreground alert', () async {
    final failingService = PushNotificationService(
      messaging: messaging,
      localNotifications: localNotifications,
      onInboxRefresh: () async => throw StateError('REST unavailable'),
    );
    addTearDown(failingService.dispose);
    await failingService.start();
    failingService.onAuthenticated();

    await failingService.handleForegroundMessage(
      _message(OrmanPushNotificationType.paymentConfirmed),
    );

    expect(localNotifications.shown, hasLength(1));
  });

  test('logout prevents FCM from refreshing the previous user inbox', () async {
    await service.start();
    service.onAuthenticated();
    service.onSigningOut();

    await service.handleForegroundMessage(
      _message(OrmanPushNotificationType.paymentConfirmed),
    );

    expect(refreshRequests, 0);
    expect(localNotifications.shown, hasLength(1));
  });

  test('unknown type is ignored', () async {
    await service.start();

    await service.handleForegroundMessage(
      const PushNotificationMessage(
        messageId: 'unknown-1',
        data: {'tipo': 'ALGO_NUEVO', 'codcuo': '20'},
      ),
    );

    expect(localNotifications.shown, isEmpty);
    expect(destinations, isEmpty);
  });

  test('invalid codcuo is ignored for foreground and navigation', () async {
    await service.start();

    await service.handleForegroundMessage(
      const PushNotificationMessage(
        messageId: 'invalid-1',
        data: {'tipo': 'PAGO_CONFIRMADO', 'codcuo': '0'},
      ),
    );
    service.handleOpenedMessage(
      const PushNotificationMessage(
        messageId: 'invalid-2',
        data: {'tipo': 'PAGO_CONFIRMADO', 'codcuo': '2.5'},
      ),
    );

    expect(localNotifications.shown, isEmpty);
    expect(destinations, isEmpty);
  });

  test(
    'background tap forwards data and does not show a local notification',
    () async {
      await service.start();

      service.handleOpenedMessage(
        _message(OrmanPushNotificationType.paymentConfirmed),
      );

      expect(destinations, hasLength(1));
      expect(destinations.single.installmentCode, 42);
      expect(localNotifications.shown, isEmpty);
    },
  );

  test(
    'terminated initial message is forwarded after service startup',
    () async {
      messaging.initialMessage = _message(
        OrmanPushNotificationType.paymentRejected,
      );

      await service.start();

      expect(destinations, hasLength(1));
      expect(
        destinations.single.type,
        OrmanPushNotificationType.paymentRejected,
      );
      expect(localNotifications.shown, isEmpty);
    },
  );

  test('local notification tap forwards its serialized destination', () async {
    await service.start();
    await service.handleForegroundMessage(
      _message(OrmanPushNotificationType.installmentDueSoon),
    );

    localNotifications.onTap!(localNotifications.shown.single.payload);

    expect(destinations, hasLength(1));
    expect(destinations.single.installmentCode, 42);
  });

  test('permission denial does not fail authentication', () async {
    localNotifications.permissionResult = false;
    final events = AuthSessionEvents();
    final manager = SessionManager(
      service: FakeAuthSessionService(),
      sessionEvents: events,
    );
    manager.addLifecycle(service);
    addTearDown(manager.dispose);
    addTearDown(events.dispose);
    await service.start();

    await manager.signIn(login: 'inquilino.demo', password: 'clave');
    await Future<void>.delayed(Duration.zero);

    expect(manager.state.status, AuthStatus.authenticated);
    expect(localNotifications.permissionRequests, 1);
  });

  test('service startup and listeners are idempotent', () async {
    await Future.wait([service.start(), service.start()]);
    messaging.emitForeground(
      _message(OrmanPushNotificationType.paymentConfirmed),
    );
    await Future<void>.delayed(Duration.zero);

    expect(localNotifications.initializeCalls, 1);
    expect(localNotifications.shown, hasLength(1));
  });
}

PushNotificationMessage _message(
  OrmanPushNotificationType type, {
  int notificationCode = 75,
  String? notificationTitle = 'Pago ORMAN',
  String? notificationBody = 'Consulta la cuota en ORMAN.',
}) => PushNotificationMessage(
  messageId: 'message-$notificationCode-${type.name}',
  title: notificationTitle,
  body: notificationBody,
  data: {
    'tipo': type.value,
    'codnot': notificationCode.toString(),
    'referenciaTipo': 'CUOTA',
    'referenciaId': '42',
    'codcuo': '42',
  },
);

class FakeMessagingGateway implements PushMessagingGateway {
  final StreamController<PushNotificationMessage> _foreground =
      StreamController<PushNotificationMessage>.broadcast(sync: true);
  final StreamController<PushNotificationMessage> _opened =
      StreamController<PushNotificationMessage>.broadcast(sync: true);
  PushNotificationMessage? initialMessage;

  @override
  Stream<PushNotificationMessage> get foregroundMessages => _foreground.stream;

  @override
  Stream<PushNotificationMessage> get openedMessages => _opened.stream;

  @override
  Future<PushNotificationMessage?> getInitialMessage() async => initialMessage;

  void emitForeground(PushNotificationMessage message) =>
      _foreground.add(message);

  Future<void> close() async {
    await _foreground.close();
    await _opened.close();
  }
}

class FakeLocalNotificationGateway implements LocalNotificationGateway {
  final List<ShownLocalNotification> shown = <ShownLocalNotification>[];
  ValueChanged<String?>? onTap;
  bool channelCreated = false;
  bool? permissionResult = true;
  int initializeCalls = 0;
  int permissionRequests = 0;

  @override
  Future<void> initialize({required ValueChanged<String?> onTap}) async {
    initializeCalls++;
    this.onTap = onTap;
  }

  @override
  Future<void> createAndroidChannel() async {
    channelCreated = true;
  }

  @override
  Future<String?> getLaunchPayload() async => null;

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    shown.add(
      ShownLocalNotification(
        id: id,
        title: title,
        body: body,
        payload: payload,
      ),
    );
  }

  @override
  Future<bool?> requestAndroidPermission() async {
    permissionRequests++;
    return permissionResult;
  }
}

class ShownLocalNotification {
  const ShownLocalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String payload;
}
