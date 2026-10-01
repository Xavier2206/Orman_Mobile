import 'package:flutter/foundation.dart';

import 'auth_session_service.dart';
import 'auth_session_events.dart';
import 'auth_session_lifecycle.dart';
import 'auth_state.dart';

/// Restaura, autentica y cierra la sesión sin controlar la navegación.
class SessionManager extends ChangeNotifier {
  SessionManager({
    required AuthSessionService service,
    required AuthSessionEvents sessionEvents,
    this.lifecycle,
  }) : _authService = service,
       _events = sessionEvents {
    if (lifecycle != null) _lifecycles.add(lifecycle!);
    _events.addListener(_onSessionInvalidated);
  }

  final AuthSessionService _authService;
  final AuthSessionEvents _events;
  final AuthSessionLifecycle? lifecycle;
  final Set<AuthSessionLifecycle> _lifecycles = <AuthSessionLifecycle>{};
  AuthState _state = const AuthState.initializing();
  bool _disposed = false;

  AuthState get state => _state;

  void addLifecycle(AuthSessionLifecycle lifecycle) {
    if (_disposed || !_lifecycles.add(lifecycle)) return;
    switch (_state.status) {
      case AuthStatus.initializing:
        break;
      case AuthStatus.unauthenticated:
        lifecycle.onUnauthenticated();
        break;
      case AuthStatus.authenticated:
        lifecycle.onAuthenticated();
        break;
    }
  }

  void removeLifecycle(AuthSessionLifecycle lifecycle) {
    _lifecycles.remove(lifecycle);
  }

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
    for (final lifecycle in List<AuthSessionLifecycle>.of(_lifecycles)) {
      lifecycle.onSigningOut();
    }
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
    if (state.status == AuthStatus.authenticated) {
      for (final lifecycle in List<AuthSessionLifecycle>.of(_lifecycles)) {
        lifecycle.onAuthenticated();
      }
    } else if (state.status == AuthStatus.unauthenticated) {
      for (final lifecycle in List<AuthSessionLifecycle>.of(_lifecycles)) {
        lifecycle.onUnauthenticated();
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final lifecycle in List<AuthSessionLifecycle>.of(_lifecycles)) {
      lifecycle.onUnauthenticated();
    }
    _lifecycles.clear();
    _events.removeListener(_onSessionInvalidated);
    super.dispose();
  }
}
