import 'package:dio/dio.dart';

import 'problem_detail.dart';

/// Error HTTP o de conectividad listo para presentar sin acoplar la UI a Dio.
class ApiException implements Exception {
  const ApiException({
    required this.detail,
    this.statusCode,
    this.errorCode,
    this.title,
    this.fieldErrors = const [],
  });

  final int? statusCode;
  final String? errorCode;
  final String? title;
  final String detail;
  final List<ProblemFieldError> fieldErrors;

  factory ApiException.fromDio(DioException error) {
    final response = error.response;
    final body = response?.data;
    if (body is Map) {
      final detail = ProblemDetail.fromJson(
        body.map((key, value) => MapEntry(key.toString(), value)),
      );
      if (detail.detail != null || detail.errorCode != null) {
        return ApiException(
          statusCode: response?.statusCode ?? detail.status,
          errorCode: detail.errorCode,
          title: detail.title,
          detail:
              detail.detail ??
              detail.title ??
              'No se pudo completar la solicitud.',
          fieldErrors: detail.fieldErrors,
        );
      }
    }

    return ApiException(
      statusCode: response?.statusCode,
      detail: switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout =>
          'La solicitud tardó demasiado. Inténtalo nuevamente.',
        DioExceptionType.connectionError =>
          'No se pudo conectar con ORMAN. Comprueba tu conexión e inténtalo nuevamente.',
        DioExceptionType.badCertificate =>
          'No se pudo validar el certificado seguro del servidor.',
        _ => 'No se pudo completar la solicitud. Inténtalo nuevamente.',
      },
    );
  }

  @override
  String toString() => 'ApiException($statusCode, $errorCode): $detail';
}
