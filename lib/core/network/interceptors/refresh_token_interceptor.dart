import 'package:dio/dio.dart';

import '../../auth/auth_session_events.dart';
import '../../auth/token_refresh_coordinator.dart';
import '../../storage/token_storage.dart';
import '../api_client.dart';
import '../api_exception.dart';

/// Refresca por single-flight y reintenta cada request protegida una sola vez.
class RefreshTokenInterceptor extends Interceptor {
  RefreshTokenInterceptor({
    required Dio client,
    required TokenStorage storage,
    required TokenRefreshCoordinator coordinator,
    required AuthSessionEvents sessionEvents,
  }) : _dio = client,
       _tokenStorage = storage,
       _refreshCoordinator = coordinator,
       _events = sessionEvents;

  final Dio _dio;
  final TokenStorage _tokenStorage;
  final TokenRefreshCoordinator _refreshCoordinator;
  final AuthSessionEvents _events;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final apiError = err.error is ApiException
        ? err.error as ApiException
        : ApiException.fromDio(err);
    final errorCode = apiError.errorCode;

    if (errorCode == 'SESSION_REVOKED' ||
        errorCode == 'INVALID_TOKEN' ||
        errorCode == 'INVALID_REFRESH_TOKEN') {
      await _invalidateSession();
      handler.next(err);
      return;
    }

    if (request.extra[ApiRequestMetadata.requiresAuth] == false ||
        errorCode != 'TOKEN_EXPIRED') {
      handler.next(err);
      return;
    }

    final retryCount =
        request.extra[ApiRequestMetadata.authRetryCount] as int? ?? 0;
    if (retryCount >= 1) {
      await _invalidateSession();
      handler.next(err);
      return;
    }

    try {
      final sentAccessToken =
          request.extra[ApiRequestMetadata.accessTokenUsed] as String?;
      final currentTokens = await _tokenStorage.readTokens();

      // Otro request ya pudo rotar los tokens mientras esta respuesta llegaba.
      final tokens =
          currentTokens != null &&
              sentAccessToken != null &&
              currentTokens.accessToken != sentAccessToken
          ? currentTokens
          : await _refreshCoordinator.refresh();

      final retryOptions = request.copyWith(
        headers: {
          ...request.headers,
          'Authorization': 'Bearer ${tokens.accessToken}',
        },
        extra: {
          ...request.extra,
          ApiRequestMetadata.authRetryCount: retryCount + 1,
        },
      );
      final response = await _dio.fetch<Object?>(retryOptions);
      handler.resolve(response);
    } on ApiException catch (exception) {
      handler.reject(
        DioException(
          requestOptions: request,
          response: err.response,
          type: DioExceptionType.badResponse,
          error: exception,
          message: exception.detail,
        ),
      );
    } on DioException catch (retryError) {
      handler.next(retryError);
    } on Object catch (unknownError) {
      handler.reject(
        DioException(
          requestOptions: request,
          response: err.response,
          type: DioExceptionType.unknown,
          error: unknownError,
        ),
      );
    }
  }

  Future<void> _invalidateSession() async {
    try {
      await _tokenStorage.clear();
    } finally {
      _events.invalidate(
        message: 'Tu sesión ya no está activa. Inicia sesión nuevamente.',
      );
    }
  }
}
