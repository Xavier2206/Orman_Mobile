import 'package:orman/core/auth/auth_session_service.dart';
import 'package:orman/core/auth/auth_session_events.dart';
import 'package:orman/core/auth/session_manager.dart';
import 'package:orman/features/auth/data/models/auth_context.dart';

class FakeAuthSessionService implements AuthSessionService {
  Future<AuthContext?> Function()? onRestore;
  Future<AuthContext> Function(String login, String password)? onSignIn;
  Future<void> Function()? onSignOut;

  @override
  Future<AuthContext?> restoreContext() =>
      onRestore?.call() ?? Future<AuthContext?>.value();

  @override
  Future<AuthContext> signIn({
    required String login,
    required String password,
  }) =>
      onSignIn?.call(login, password) ??
      Future<AuthContext>.value(testAuthContext);

  @override
  Future<void> signOut() => onSignOut?.call() ?? Future<void>.value();

  @override
  String messageFor(Object error) => error.toString();
}

AuthContext get testAuthContext => const AuthContext(
  usuario: AuthContextUsuario(login: 'inquilino.demo', codper: 123),
  persona: AuthContextPersona(nombre: 'Juan', ap: 'Pérez', am: 'López'),
  roles: [AuthContextRol(codr: 8, nombre: 'INQUILINO', menus: [])],
);

SessionManager createTestSessionManager({FakeAuthSessionService? service}) =>
    SessionManager(
      service: service ?? FakeAuthSessionService(),
      sessionEvents: AuthSessionEvents(),
    );
