import 'dart:async';

import 'package:dio/dio.dart';

import '../../features/auth/data/models/login_response.dart';
import '../../features/auth/data/models/token_pair.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../storage/token_storage.dart';
import 'auth_session_events.dart';

/// Hace un único refresh por tanda de respuestas expiradas.
class TokenRefreshCoordinator {
  TokenRefreshCoordinator({
    required Dio client,
    required TokenStorage storage,
    required AuthSessionEvents sessionEvents,
  }) : _refreshDio = client,
       _tokenStorage = storage,
       _events = sessionEvents;

  final Dio _refreshDio;
  final TokenStorage _tokenStorage;
  final AuthSessionEvents _events;
  Future<TokenPair>? _refreshInFlight;

  Future<TokenPair> refresh() {
    final current = _refreshInFlight;
    if (current != null) return current;

    late final Future<TokenPair> operation;
    operation = _performRefresh().whenComplete(() {
      if (identical(_refreshInFlight, operation)) _refreshInFlight = null;
    });
    _refreshInFlight = operation;
    return operation;
  }

  Future<TokenPair> _performRefresh() async {
    try {
      final currentTokens = await _tokenStorage.readTokens();
      if (currentTokens == null) {
        throw const ApiException(
          statusCode: 401,
          errorCode: 'INVALID_REFRESH_TOKEN',
          title: 'Sesión no válida',
          detail: 'Tu sesión ya no está activa. Inicia sesión nuevamente.',
        );
      }

      final response = await _refreshDio.post<Object?>(
        ApiEndpoints.refresh,
        data: {'refreshToken': currentTokens.refreshToken},
        options: Options(contentType: Headers.jsonContentType),
      );
      final payload = response.data;
      if (payload is! Map) throw const FormatException();
      final loginResponse = LoginResponse.fromJson(
        payload.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (loginResponse.status != 'AUTHENTICATED') {
        throw const FormatException();
      }

      final rotatedTokens = loginResponse.tokenPair;
      // La pareja completa se persiste antes de liberar cualquier request en espera.
      await _tokenStorage.saveTokens(rotatedTokens);
      return rotatedTokens;
    } on DioException catch (error) {
      final exception = ApiException.fromDio(error);
      await _invalidate(exception);
      throw exception;
    } on ApiException catch (error) {
      await _invalidate(error);
      rethrow;
    } on Object {
      const exception = ApiException(
        errorCode: 'INVALID_REFRESH_RESPONSE',
        title: 'No se pudo renovar la sesión',
        detail: 'Tu sesión ya no está activa. Inicia sesión nuevamente.',
      );
      await _invalidate(exception);
      throw exception;
    }
  }

  Future<void> _invalidate(ApiException exception) async {
    try {
      await _tokenStorage.clear();
    } finally {
      _events.invalidate(
        message: 'Tu sesión ya no está activa. Inicia sesión nuevamente.',
      );
    }
  }
}
