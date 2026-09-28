import 'package:flutter_test/flutter_test.dart';
import 'package:orman/core/auth/auth_session_events.dart';
import 'package:orman/core/auth/auth_state.dart';
import 'package:orman/core/auth/session_manager.dart';

import '../../support/fake_auth_session_service.dart';

void main() {
  test(
    'restores a saved session before the app selects authenticated UI',
    () async {
      final service = FakeAuthSessionService()
        ..onRestore = () async => testAuthContext;
      final manager = createTestSessionManager(service: service);
      addTearDown(manager.dispose);

      expect(manager.state.status, AuthStatus.initializing);
      await manager.restoreSession();

      expect(manager.state.status, AuthStatus.authenticated);
      expect(manager.state.context?.usuario.login, 'inquilino.demo');
    },
  );

  test('no stored session resolves to unauthenticated', () async {
    final manager = createTestSessionManager();
    addTearDown(manager.dispose);

    await manager.restoreSession();

    expect(manager.state.status, AuthStatus.unauthenticated);
  });

  test('sign in and sign out update state and invoke the service', () async {
    var receivedLogin = '';
    var receivedPassword = '';
    var logoutCalls = 0;
    final service = FakeAuthSessionService()
      ..onSignIn = (login, password) async {
        receivedLogin = login;
        receivedPassword = password;
        return testAuthContext;
      }
      ..onSignOut = () async {
        logoutCalls++;
      };
    final manager = createTestSessionManager(service: service);
    addTearDown(manager.dispose);

    await manager.signIn(login: 'inquilino.demo', password: 'clave-privada');
    expect(manager.state.status, AuthStatus.authenticated);
    expect(receivedLogin, 'inquilino.demo');
    expect(receivedPassword, 'clave-privada');

    await manager.signOut();
    expect(logoutCalls, 1);
    expect(manager.state.status, AuthStatus.unauthenticated);
  });

  test('session invalidation immediately returns state to login', () async {
    final service = FakeAuthSessionService()
      ..onRestore = () async => testAuthContext;
    final events = AuthSessionEvents();
    final manager = SessionManager(service: service, sessionEvents: events);
    addTearDown(manager.dispose);
    addTearDown(events.dispose);

    await manager.restoreSession();
    events.invalidate(message: 'Tu sesión ya no está activa.');

    expect(manager.state.status, AuthStatus.unauthenticated);
    expect(manager.state.message, 'Tu sesión ya no está activa.');
  });
}
