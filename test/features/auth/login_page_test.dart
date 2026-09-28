import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/app/theme/app_theme.dart';
import 'package:orman/app/theme/orman_theme_controller.dart';
import 'package:orman/app/theme/orman_theme_kind.dart';
import 'package:orman/core/network/api_exception.dart';
import 'package:orman/features/auth/presentation/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_session_service.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('validates required login and password fields', (tester) async {
    final manager = createTestSessionManager();
    final themeController = OrmanThemeController();
    addTearDown(manager.dispose);
    addTearDown(themeController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forKind(OrmanThemeKind.orman),
        home: LoginPage(
          sessionManager: manager,
          themeController: themeController,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu usuario.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login-field')),
      'inquilino.demo',
    );
    await tester.enterText(find.byKey(const Key('password-field')), '        ');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
  });

  testWidgets(
    'shows backend credential detail and toggles password visibility',
    (tester) async {
      final service = FakeAuthSessionService()
        ..onSignIn = (login, password) async {
          throw const ApiException(
            statusCode: 401,
            errorCode: 'INVALID_CREDENTIALS',
            title: 'Credenciales inválidas',
            detail: 'Las credenciales no son válidas.',
          );
        };
      final manager = createTestSessionManager(service: service);
      final themeController = OrmanThemeController();
      addTearDown(manager.dispose);
      addTearDown(themeController.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.forKind(OrmanThemeKind.orman),
          home: LoginPage(
            sessionManager: manager,
            themeController: themeController,
          ),
        ),
      );

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
      expect(find.text('Las credenciales no son válidas.'), findsOneWidget);

      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pumpAndSettle();
      final passwordField = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const Key('password-field')),
          matching: find.byType(EditableText),
        ),
      );
      expect(passwordField.obscureText, isFalse);
    },
  );

  testWidgets('local validation enforces password length without trimming it', (
    tester,
  ) async {
    final manager = createTestSessionManager();
    final themeController = OrmanThemeController();
    addTearDown(manager.dispose);
    addTearDown(themeController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.forKind(OrmanThemeKind.orman),
        home: LoginPage(
          sessionManager: manager,
          themeController: themeController,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('login-field')), 'user');
    await tester.enterText(find.byKey(const Key('password-field')), ' short ');
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pumpAndSettle();

    expect(
      find.text('La contraseña debe tener entre 8 y 72 caracteres.'),
      findsOneWidget,
    );
  });
}
