import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/app/app.dart';
import 'package:orman/app/design_system_showcase_page.dart';
import 'package:orman/app/theme/app_theme.dart';
import 'package:orman/app/theme/orman_theme_controller.dart';
import 'package:orman/app/theme/orman_theme_kind.dart';
import 'package:orman/features/auth/data/models/auth_context.dart';
import 'package:orman/features/auth/presentation/authenticated_home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_auth_session_service.dart';
import 'support/fake_portal_api.dart';

void main() {
  testWidgets('OrmanApp waits for restoration and then opens Login', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final restored = Completer<AuthContext?>();
    final service = FakeAuthSessionService()..onRestore = () => restored.future;
    final session = createTestSessionManager(service: service);
    await tester.pumpWidget(
      OrmanApp(sessionManager: session, apiClient: createFakePortalApi()),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Bienvenido a ORMAN'), findsNothing);

    restored.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Bienvenido a ORMAN'), findsOneWidget);
  });

  testWidgets(
    'restored session opens the tenant home and logout returns to Login',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      var logoutCalls = 0;
      final service = FakeAuthSessionService()
        ..onRestore = () async {
          return testAuthContext;
        }
        ..onSignOut = () async {
          logoutCalls++;
        };
      final session = createTestSessionManager(service: service);

      await tester.pumpWidget(
        OrmanApp(sessionManager: session, apiClient: createFakePortalApi()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AuthenticatedHomePage), findsOneWidget);
      expect(find.text('Hola, Juan'), findsOneWidget);
      expect(find.text('Mis contratos'), findsOneWidget);
      expect(find.text('Edificio ORMAN'), findsOneWidget);
      expect(find.text('Unidad A-3'), findsOneWidget);
      expect(find.text('VIGENTE'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.textContaining('accessToken'), findsNothing);
      expect(find.textContaining('refreshToken'), findsNothing);
      expect(find.textContaining('11111111-2222-3333'), findsNothing);

      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(logoutCalls, 1);
      expect(find.text('Bienvenido a ORMAN'), findsOneWidget);
    },
  );

  testWidgets('successful Login switches to the authenticated home', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = FakeAuthSessionService()
      ..onSignIn = (login, password) async => testAuthContext;
    final session = createTestSessionManager(service: service);

    await tester.pumpWidget(
      OrmanApp(sessionManager: session, apiClient: createFakePortalApi()),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('login-field')),
      'inquilino.demo',
    );
    await tester.enterText(
      find.byKey(const Key('password-field')),
      'clave-ficticia',
    );
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Juan'), findsOneWidget);
    expect(find.text('Mis contratos'), findsOneWidget);
  });

  testWidgets('showcase adapts at phone and tablet widths', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final themeController = OrmanThemeController();
    addTearDown(themeController.dispose);

    for (final size in const <Size>[
      Size(360, 800),
      Size(390, 800),
      Size(600, 900),
      Size(1024, 900),
    ]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forKind(OrmanThemeKind.orman),
          home: DesignSystemShowcasePage(themeController: themeController),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'width ${size.width}');
    }
  });
}
