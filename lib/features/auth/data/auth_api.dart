import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import 'models/auth_context.dart';
import 'models/login_request.dart';
import 'models/login_response.dart';

/// Adaptador tipado de los endpoints de autenticación.
class AuthApi {
  const AuthApi(this._client);

  final ApiClient _client;

  Future<LoginResponse> login(LoginRequest request) async =>
      LoginResponse.fromJson(
        _jsonObject(
          await _client.postJson(
            ApiEndpoints.login,
            data: request.toJson(),
            requiresAuth: false,
          ),
        ),
      );

  Future<AuthContext> getContext() async => AuthContext.fromJson(
    _jsonObject(await _client.getJson(ApiEndpoints.context)),
  );

  Future<void> logout() => _client.postEmpty(ApiEndpoints.logout);
}

Map<String, dynamic> _jsonObject(Object? value) {
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  throw const FormatException('El backend devolvió una respuesta inesperada.');
}
