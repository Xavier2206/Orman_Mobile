import 'package:dio/dio.dart';

import '../api_exception.dart';

/// Normaliza errores HTTP antes de que lleguen a los adaptadores de datos.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }

    final exception = ApiException.fromDio(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        response: err.response,
        type: err.type,
        error: exception,
        stackTrace: err.stackTrace,
        message: exception.detail,
      ),
    );
  }
}
