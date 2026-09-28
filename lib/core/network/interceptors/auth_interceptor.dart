import 'package:dio/dio.dart';

import '../../storage/token_storage.dart';
import '../api_client.dart';

/// Adjunta el access token actual a requests protegidos.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[ApiRequestMetadata.requiresAuth] == false) {
      handler.next(options);
      return;
    }

    try {
      final accessToken = await _tokenStorage.readAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        options.headers.remove('Authorization');
        options.extra.remove(ApiRequestMetadata.accessTokenUsed);
      } else {
        options.headers['Authorization'] = 'Bearer $accessToken';
        options.extra[ApiRequestMetadata.accessTokenUsed] = accessToken;
      }
      handler.next(options);
    } on Object catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }
}
