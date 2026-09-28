import 'package:dio/dio.dart';
import 'dart:typed_data';

import 'api_exception.dart';

abstract final class ApiRequestMetadata {
  static const requiresAuth = 'orman.requiresAuth';
  static const accessTokenUsed = 'orman.accessTokenUsed';
  static const authRetryCount = 'orman.authRetryCount';
}

/// Entrada única para requests HTTP y traducción de Dio a errores de app.
class ApiClient {
  const ApiClient(this.dio);

  final Dio dio;

  Future<Object?> getJson(
    String path, {
    bool requiresAuth = true,
    Map<String, Object?>? queryParameters,
  }) => _request(
    path,
    method: 'GET',
    requiresAuth: requiresAuth,
    queryParameters: queryParameters,
  );

  Future<Object?> postJson(
    String path, {
    Object? data,
    bool requiresAuth = true,
  }) => _request(path, method: 'POST', data: data, requiresAuth: requiresAuth);

  Future<void> postEmpty(String path, {bool requiresAuth = true}) async {
    await _request(path, method: 'POST', requiresAuth: requiresAuth);
  }

  Future<Object?> patchJson(
    String path, {
    Object? data,
    bool requiresAuth = true,
  }) => _request(path, method: 'PATCH', data: data, requiresAuth: requiresAuth);

  Future<Object?> patchEmpty(String path, {bool requiresAuth = true}) =>
      patchJson(path, requiresAuth: requiresAuth);

  Future<Object?> postMultipart(
    String path, {
    required FormData data,
    bool requiresAuth = true,
  }) => _request(
    path,
    method: 'POST',
    data: data,
    contentType: Headers.multipartFormDataContentType,
    requiresAuth: requiresAuth,
  );

  Future<Uint8List> getBytes(String path, {bool requiresAuth = true}) async {
    try {
      final response = await dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          extra: {ApiRequestMetadata.requiresAuth: requiresAuth},
        ),
      );
      return Uint8List.fromList(response.data ?? const <int>[]);
    } on DioException catch (error) {
      final mapped = error.error;
      if (mapped is ApiException) throw mapped;
      throw ApiException.fromDio(error);
    }
  }

  void close({bool force = false}) => dio.close(force: force);

  Future<Object?> _request(
    String path, {
    required String method,
    Object? data,
    required bool requiresAuth,
    Map<String, Object?>? queryParameters,
    String? contentType,
  }) async {
    try {
      final response = await dio.request<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          contentType: contentType ?? Headers.jsonContentType,
          extra: {ApiRequestMetadata.requiresAuth: requiresAuth},
        ),
      );
      return response.data;
    } on DioException catch (error) {
      final mapped = error.error;
      if (mapped is ApiException) throw mapped;
      throw ApiException.fromDio(error);
    }
  }
}
