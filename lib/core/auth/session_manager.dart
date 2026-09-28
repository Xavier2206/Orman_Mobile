import 'package:flutter/foundation.dart';

import 'auth_session_service.dart';
import 'auth_session_events.dart';
import 'auth_state.dart';

/// Restaura, autentica y cierra la sesión sin controlar la navegación.
class SessionManager extends ChangeNotifier {
  SessionManager({
    required AuthSessionService service,
    required AuthSessionEvents sessionEvents,
  }) : _authService = service,
       _events = sessionEvents {
    _events.addListener(_onSessionInvalidated);
  }

  final AuthSessionService _authService;
  final AuthSessionEvents _events;
  AuthState _state = const AuthState.initializing();
  bool _disposed = false;

  AuthState get state => _state;

  Future<void> restoreSession() async {
    try {
      final context = await _authService.restoreContext();
      _setState(
        context == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(context),
      );
    } on Object catch (error) {
      if (_state.status == AuthStatus.unauthenticated &&
          _state.message != null) {
        return;
      }
      _setState(
        AuthState.unauthenticated(message: _authService.messageFor(error)),
      );
    }
  }

  Future<void> signIn({required String login, required String password}) async {
    try {
      final context = await _authService.signIn(
        login: login,
        password: password,
      );
      _setState(AuthState.authenticated(context));
      _events.clearMessage();
    } on Object {
      _setState(const AuthState.unauthenticated());
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } finally {
      _setState(const AuthState.unauthenticated());
      _events.clearMessage();
    }
  }

  void _onSessionInvalidated() {
    _setState(AuthState.unauthenticated(message: _events.message));
  }

  void _setState(AuthState state) {
    if (_disposed) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _events.removeListener(_onSessionInvalidated);
    super.dispose();
  }
}
