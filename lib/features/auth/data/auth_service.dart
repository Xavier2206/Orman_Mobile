import '../../../core/network/api_exception.dart';
import '../../../core/auth/auth_session_service.dart';
import '../../../core/storage/token_storage.dart';
import 'auth_api.dart';
import 'device_identity.dart';
import 'models/auth_context.dart';
import 'models/login_request.dart';

/// Orquesta login, verificación del contexto y salida local/remota.
class AuthService implements AuthSessionService {
  const AuthService({
    required AuthApi authApi,
    required TokenStorage storage,
    required DeviceIdProvider identity,
    required DeviceNameProvider device,
  }) : _api = authApi,
       _tokenStorage = storage,
       _deviceIdProvider = identity,
       _deviceNameProvider = device;

  final AuthApi _api;
  final TokenStorage _tokenStorage;
  final DeviceIdProvider _deviceIdProvider;
  final DeviceNameProvider _deviceNameProvider;

  @override
  Future<AuthContext?> restoreContext() async {
    if (await _tokenStorage.readTokens() == null) return null;
    return _api.getContext();
  }

  @override
  Future<AuthContext> signIn({
    required String login,
    required String password,
  }) async {
    final request = LoginRequest(
      login: login.trim(),
      password: password,
      deviceId: await _deviceIdProvider.getStableId(),
      deviceName: await _deviceNameProvider.getDeviceName(),
    );
    final response = await _api.login(request);

    if (response.status != 'AUTHENTICATED') {
      throw const ApiException(
        statusCode: 401,
        errorCode: 'MOBILE_AUTH_CHALLENGE_UNSUPPORTED',
        title: 'No se pudo iniciar sesión',
        detail:
            'El servidor solicitó un paso de autenticación no disponible en la app móvil.',
      );
    }

    try {
      await _tokenStorage.saveTokens(response.tokenPair);
      return await _api.getContext();
    } on Object {
      await _tokenStorage.clear();
      rethrow;
    }
  }

  /// Siempre elimina la sesión local aunque el endpoint remoto no responda.
  @override
  Future<void> signOut() async {
    try {
      if (await _tokenStorage.readTokens() != null) await _api.logout();
    } on Object {
      // El usuario puede cerrar sesión localmente cuando el backend no está disponible.
    } finally {
      await _tokenStorage.clear();
    }
  }

  @override
  String messageFor(Object error) => error is ApiException
      ? error.detail
      : 'No se pudo verificar la sesión. Comprueba tu conexión e inténtalo nuevamente.';
}
