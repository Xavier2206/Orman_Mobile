import 'package:flutter/foundation.dart';

import '../../features/auth/data/models/auth_context.dart';

enum AuthStatus { initializing, unauthenticated, authenticated }

@immutable
class AuthState {
  const AuthState._({required this.status, this.context, this.message});

  const AuthState.initializing() : this._(status: AuthStatus.initializing);

  const AuthState.unauthenticated({String? message})
    : this._(status: AuthStatus.unauthenticated, message: message);

  const AuthState.authenticated(AuthContext context)
    : this._(status: AuthStatus.authenticated, context: context);

  final AuthStatus status;
  final AuthContext? context;
  final String? message;
}
