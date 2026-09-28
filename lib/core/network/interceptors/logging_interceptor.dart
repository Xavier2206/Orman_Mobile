import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Diagnóstico mínimo: nunca escribe headers ni bodies que puedan tener secretos.
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) debugPrint('[API] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[API] ${response.statusCode} ${response.requestOptions.path}',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      debugPrint(
        '[API] ${err.response?.statusCode ?? 'network'} '
        '${err.requestOptions.path}',
      );
    }
    handler.next(err);
  }
}
