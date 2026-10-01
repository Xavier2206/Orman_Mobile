import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:orman/core/network/api_client.dart';
import 'package:orman/features/notifications/data/notification_navigation_coordinator.dart';
import 'package:orman/features/notifications/models/push_notification_destination.dart';

void main() {
  testWidgets('tap before authentication is held until session is ready', (
    tester,
  ) async {
    final fixture = NavigationFixture();
    addTearDown(fixture.dispose);
    await _pumpFrame(tester);
    final destination = _destination();

    fixture.coordinator.receive(destination);
    await tester.pump();
    expect(fixture.openedInstallments, isEmpty);
    expect(fixture.coordinator.hasPendingDestination, isTrue);

    fixture.coordinator.onAuthenticated();
    await tester.pump();

    expect(fixture.openedInstallments, [42]);
    expect(fixture.coordinator.hasPendingDestination, isFalse);
  });

  testWidgets('logout clears a destination waiting for a session', (
    tester,
  ) async {
    final fixture = NavigationFixture();
    addTearDown(fixture.dispose);
    await _pumpFrame(tester);
    fixture.coordinator.receive(_destination());
    fixture.coordinator.onSigningOut();
    fixture.coordinator.onAuthenticated();

    await tester.pump();

    expect(fixture.openedInstallments, isEmpty);
    expect(fixture.coordinator.hasPendingDestination, isFalse);
  });

  testWidgets('expired session drops a pending tap before another login', (
    tester,
  ) async {
    final fixture = NavigationFixture();
    addTearDown(fixture.dispose);
    await _pumpFrame(tester);
    fixture.coordinator.onAuthenticated();
    fixture.coordinator.receive(_destination());
    fixture.coordinator.onUnauthenticated();
    fixture.coordinator.onAuthenticated();

    await tester.pump();

    expect(fixture.openedInstallments, isEmpty);
    expect(fixture.coordinator.hasPendingDestination, isFalse);
  });

  testWidgets('duplicate notification taps navigate only once', (tester) async {
    final fixture = NavigationFixture();
    addTearDown(fixture.dispose);
    await _pumpFrame(tester);
    final destination = _destination();

    fixture.coordinator.onAuthenticated();
    fixture.coordinator.receive(destination);
    fixture.coordinator.receive(destination);
    await tester.pump();
    fixture.coordinator.receive(destination);
    await tester.pump();

    expect(fixture.openedInstallments, [42]);
  });

  testWidgets('terminated message can wait for restored authentication', (
    tester,
  ) async {
    final fixture = NavigationFixture();
    addTearDown(fixture.dispose);
    await _pumpFrame(tester);

    fixture.coordinator.receive(_destination(notificationCode: null));
    expect(fixture.coordinator.hasPendingDestination, isTrue);
    fixture.coordinator.onAuthenticated();
    await tester.pump();

    expect(fixture.openedInstallments, [42]);
  });

  testWidgets('mark-read failure does not block opening the installment', (
    tester,
  ) async {
    final fixture = NavigationFixture(failMarkRead: true);
    addTearDown(fixture.dispose);
    await _pumpFrame(tester);
    fixture.coordinator.onAuthenticated();
    fixture.coordinator.receive(_destination());

    await tester.pump();
    await tester.pump();

    expect(fixture.openedInstallments, [42]);
  });

  testWidgets('invalid codcuo payload cannot create a navigation destination', (
    tester,
  ) async {
    final fixture = NavigationFixture();
    addTearDown(fixture.dispose);
    await _pumpFrame(tester);
    final destination = PushNotificationDestination.fromData(const {
      'tipo': 'PAGO_CONFIRMADO',
      'codcuo': '-42',
      'codnot': '75',
    });
    fixture.coordinator.onAuthenticated();
    if (destination != null) fixture.coordinator.receive(destination);

    await tester.pump();

    expect(destination, isNull);
    expect(fixture.openedInstallments, isEmpty);
  });
}

Future<void> _pumpFrame(WidgetTester tester) => tester.pumpWidget(
  const Directionality(textDirection: TextDirection.ltr, child: SizedBox()),
);

PushNotificationDestination _destination({int? notificationCode = 75}) =>
    PushNotificationDestination(
      installmentCode: 42,
      notificationCode: notificationCode,
      type: OrmanPushNotificationType.paymentConfirmed,
      messageId: 'message-42',
    );

class NavigationFixture {
  NavigationFixture({bool failMarkRead = false}) {
    _dio = Dio(BaseOptions(baseUrl: 'https://orman-test.invalid'));
    coordinator = NotificationNavigationCoordinator(
      apiClient: ApiClient(_dio),
      navigateToInstallment: (code) {
        openedInstallments.add(code);
        return true;
      },
      markRead: (code) async {
        if (failMarkRead) throw StateError('mark read unavailable');
      },
    );
  }

  late final Dio _dio;
  late final NotificationNavigationCoordinator coordinator;
  final List<int> openedInstallments = <int>[];

  void dispose() {
    coordinator.dispose();
    _dio.close(force: true);
  }
}
