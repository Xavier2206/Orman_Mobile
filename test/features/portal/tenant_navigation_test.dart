import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/app/theme/app_theme.dart';
import 'package:orman/app/theme/orman_theme_kind.dart';
import 'package:orman/features/contracts/presentation/contract_detail_page.dart';
import 'package:orman/features/notifications/presentation/notifications_page.dart';
import 'package:orman/features/notifications/data/notification_refresh_signal.dart';
import 'package:orman/features/payments/presentation/installment_detail_page.dart';
import 'package:orman/features/payments/presentation/payment_form_page.dart';
import 'package:orman/features/contracts/models/tenant_installment.dart';

import '../../support/fake_http_adapter.dart';
import '../../support/fake_portal_api.dart';

void main() {
  testWidgets('contract detail shows the real contract fields and its quotas', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forKind(OrmanThemeKind.orman),
        home: ContractDetailPage(
          apiClient: createFakePortalApi(),
          contractCode: 12,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edificio ORMAN'), findsOneWidget);
    expect(find.text('Unidad A-3'), findsOneWidget);
    expect(find.text('Monto mensual'), findsOneWidget);
    expect(find.text('Garantía'), findsOneWidget);
    expect(find.text('Cuotas'), findsOneWidget);
    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(find.text('En revisión: Bs 500,00'), findsOneWidget);
  });

  testWidgets('installment detail shows backend saldo and review amount', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forKind(OrmanThemeKind.orman),
        home: InstallmentDetailPage(
          apiClient: createFakePortalApi(),
          installmentCode: 88,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pagado confirmado'), findsOneWidget);
    expect(find.text('Pendiente de revisión'), findsOneWidget);
    expect(find.text('Saldo'), findsOneWidget);
    expect(find.text('Vencida'), findsNothing);
    expect(find.text('VENCIDA'), findsOneWidget);
    expect(find.text('Registrar pago'), findsOneWidget);
  });

  testWidgets('paid and annulled installments cannot register a payment', (
    tester,
  ) async {
    for (final status in ['PAGADA', 'ANULADA']) {
      final api = createFakePortalApi(
        onRequest: (options, stream) async {
          if (options.path.endsWith('/inquilino/cuotas/88')) {
            return jsonResponse(
              installmentJson(
                estado: status,
                saldo: status == 'PAGADA' ? 0 : 1500,
              ),
            );
          }
          return jsonResponse({});
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forKind(OrmanThemeKind.orman),
          home: InstallmentDetailPage(
            key: ValueKey(status),
            apiClient: api,
            installmentCode: 88,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Registrar pago'), findsNothing, reason: status);
      expect(find.text(status), findsOneWidget);
    }
  });

  testWidgets(
    'review payments covering the remaining saldo block new payment',
    (tester) async {
      final api = createFakePortalApi(
        onRequest: (options, stream) async {
          if (options.path.endsWith('/inquilino/cuotas/88')) {
            return jsonResponse(
              installmentJson(
                estado: 'PENDIENTE',
                saldo: 500,
                montoPendienteRevision: 500,
              ),
            );
          }
          return jsonResponse({});
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forKind(OrmanThemeKind.orman),
          home: InstallmentDetailPage(apiClient: api, installmentCode: 88),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Registrar pago'), findsNothing);
      expect(
        find.text(
          'Tienes un pago pendiente de revisión que cubre el saldo restante.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'payment form blocks amount entry when nothing remains to register',
    (tester) async {
      final installment = TenantInstallment.fromJson(
        installmentJson(saldo: 500, montoPendienteRevision: 500),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forKind(OrmanThemeKind.orman),
          home: PaymentFormPage(
            apiClient: createFakePortalApi(),
            installment: installment,
          ),
        ),
      );
      await tester.pumpAndSettle();
      final amountField = tester.widget<TextFormField>(
        find.byKey(const Key('payment-amount-field')),
      );
      expect(amountField.enabled, isFalse);
      expect(
        find.text(
          'Puedes registrar hasta Bs 0,00. Se permiten pagos parciales.',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('history button explains the tenant permission restriction', (
    tester,
  ) async {
    final requestedPaths = <String>[];
    final api = createFakePortalApi(
      onRequest: (options, stream) async {
        requestedPaths.add(options.path);
        if (options.path.endsWith('/inquilino/cuotas/88')) {
          return jsonResponse(installmentJson());
        }
        return jsonResponse({});
      },
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forKind(OrmanThemeKind.orman),
        home: InstallmentDetailPage(apiClient: api, installmentCode: 88),
      ),
    );
    await tester.pumpAndSettle();
    requestedPaths.clear();

    await tester.tap(find.text('Historial de pagos'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'El historial de pagos todavía no está disponible para inquilinos.',
      ),
      findsOneWidget,
    );
    expect(requestedPaths.where((path) => path.endsWith('/pagos')), isEmpty);
  });

  testWidgets('QR sheet explains when the owner has no current QR', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forKind(OrmanThemeKind.orman),
        home: InstallmentDetailPage(
          apiClient: createFakePortalApi(),
          installmentCode: 88,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver QR de cobro'));
    await tester.pumpAndSettle();

    expect(
      find.text('La propietaria no tiene un QR de cobro vigente.'),
      findsOneWidget,
    );
  });

  testWidgets('payment form enforces saldo and requires a proof image', (
    tester,
  ) async {
    final installment = TenantInstallment.fromJson(installmentJson());
    final requestPaths = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forKind(OrmanThemeKind.orman),
        home: PaymentFormPage(
          apiClient: createFakePortalApi(
            onRequest: (options, stream) async {
              requestPaths.add(options.path);
              return jsonResponse({});
            },
          ),
          installment: installment,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saldo pendiente'), findsOneWidget);
    expect(find.text('Saldo disponible'), findsNothing);
    expect(find.text('En revisión'), findsOneWidget);
    expect(
      find.text(
        'Puedes registrar hasta Bs 1.000,00. Se permiten pagos parciales.',
      ),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('payment-amount-field')),
      '1500,01',
    );
    await tester.ensureVisible(find.text('Enviar comprobante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar comprobante'));
    await tester.pumpAndSettle();
    expect(
      find.text('El monto supera el máximo que puedes registrar: Bs 1.000,00.'),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const Key('payment-amount-field')),
      '500',
    );
    await tester.ensureVisible(find.text('Enviar comprobante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar comprobante'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona el comprobante del pago.'), findsOneWidget);
    expect(requestPaths, isEmpty);
  });

  testWidgets('CUOTA notification opens a freshly loaded quota detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forKind(OrmanThemeKind.orman),
        home: NotificationsPage(
          apiClient: createFakePortalApi(),
          onUnreadCountChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuota pendiente'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle de cuota'), findsOneWidget);
    expect(find.text('Septiembre 2026'), findsOneWidget);
    expect(find.text('Bs 1.500,00'), findsOneWidget);
  });

  testWidgets(
    'an inbox refresh reloads the open list and REST unread summary',
    (tester) async {
      final requestPaths = <String>[];
      final signal = NotificationRefreshSignal()..onAuthenticated();
      addTearDown(signal.dispose);
      final api = createFakePortalApi(
        onRequest: (options, stream) async {
          requestPaths.add(options.path);
          if (options.path.endsWith('/notificaciones/resumen')) {
            return jsonResponse({'noLeidas': 4});
          }
          if (options.path.endsWith('/notificaciones')) {
            return jsonResponse({
              'content': [notificationJson()],
              'page': 0,
              'size': 20,
              'totalPages': 1,
              'last': true,
            });
          }
          return jsonResponse({});
        },
      );
      final unreadCounts = <int>[];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forKind(OrmanThemeKind.orman),
          home: NotificationsPage(
            apiClient: api,
            onUnreadCountChanged: unreadCounts.add,
            refreshSignal: signal,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        requestPaths.where((path) => path.endsWith('/notificaciones')),
        hasLength(1),
      );
      expect(unreadCounts, [4]);

      signal.requestRefresh();
      await tester.pumpAndSettle();

      expect(
        requestPaths.where((path) => path.endsWith('/notificaciones')),
        hasLength(2),
      );
      expect(
        requestPaths.where((path) => path.endsWith('/notificaciones/resumen')),
        hasLength(2),
      );
      expect(unreadCounts, [4, 4]);
      expect(find.text('Cuota pendiente'), findsOneWidget);
    },
  );

  testWidgets('tenant portal contract cards fit narrow phone widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final width in [360.0, 390.0, 412.0]) {
      tester.view.physicalSize = Size(width, 800);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forKind(OrmanThemeKind.orman),
          home: NotificationsPage(
            apiClient: createFakePortalApi(),
            onUnreadCountChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'width $width');
    }
  });
}
