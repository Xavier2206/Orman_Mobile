import '../../features/auth/data/models/auth_context.dart';

/// Contrato que usa el gestor de sesión, independiente de Dio y la UI.
abstract interface class AuthSessionService {
  Future<AuthContext?> restoreContext();
  Future<AuthContext> signIn({required String login, required String password});
  Future<void> signOut();
  String messageFor(Object error);
}
