import 'json_readers.dart';

/// Representación tipada de errores RFC 9457 emitidos por el backend.
class ProblemDetail {
  const ProblemDetail({
    this.type,
    this.title,
    this.status,
    this.detail,
    this.instance,
    this.errorCode,
    this.timestamp,
    this.traceId,
    this.fieldErrors = const [],
  });

  final String? type;
  final String? title;
  final int? status;
  final String? detail;
  final String? instance;
  final String? errorCode;
  final DateTime? timestamp;
  final String? traceId;
  final List<ProblemFieldError> fieldErrors;

  factory ProblemDetail.fromJson(Map<String, dynamic> json) {
    final rawTimestamp = json['timestamp'];
    final rawErrors = json['fieldErrors'];

    return ProblemDetail(
      type: _readString(json['type']),
      title: _readString(json['title']),
      status: _readInt(json['status']),
      detail: _readString(json['detail']),
      instance: _readString(json['instance']),
      errorCode: _readString(json['errorCode']),
      timestamp: jsonDate(rawTimestamp),
      traceId: _readString(json['traceId']),
      fieldErrors: rawErrors is List
          ? rawErrors
                .whereType<Map>()
                .map(
                  (error) => ProblemFieldError.fromJson(
                    error.map((key, value) => MapEntry(key.toString(), value)),
                  ),
                )
                .toList(growable: false)
          : const [],
    );
  }

  static String? _readString(Object? value) => value is String ? value : null;

  static int? _readInt(Object? value) => value is int
      ? value
      : value is num
      ? value.toInt()
      : null;
}

class ProblemFieldError {
  const ProblemFieldError({required this.field, required this.message});

  final String field;
  final String message;

  factory ProblemFieldError.fromJson(Map<String, dynamic> json) =>
      ProblemFieldError(
        field: json['field'] is String ? json['field'] as String : '',
        message: json['message'] is String ? json['message'] as String : '',
      );
}
