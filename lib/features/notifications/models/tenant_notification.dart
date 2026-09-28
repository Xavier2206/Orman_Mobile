import '../../../core/network/json_readers.dart';

class TenantNotification {
  const TenantNotification({
    required this.code,
    required this.title,
    required this.message,
    required this.isRead,
    this.type,
    this.referenceType,
    this.referenceId,
    this.createdAt,
    this.readAt,
  });

  final int code;
  final String title;
  final String message;
  final String? type;
  final String? referenceType;
  final int? referenceId;
  final DateTime? createdAt;
  final bool isRead;
  final DateTime? readAt;

  factory TenantNotification.fromJson(JsonMap json) {
    final code = jsonInt(json['codnot']);
    if (code == null) {
      throw const FormatException('La notificación no incluye codnot.');
    }
    return TenantNotification(
      code: code,
      type: jsonString(json['tipo']),
      title: jsonString(json['titulo']) ?? '',
      message: jsonString(json['mensaje']) ?? '',
      referenceType: jsonString(json['referenciaTipo']),
      referenceId: jsonInt(json['referenciaId']),
      createdAt: jsonDate(json['fechaCreacion']),
      isRead: json['leida'] == true,
      readAt: jsonDate(json['fechaLectura']),
    );
  }
}

class TenantNotificationPage {
  const TenantNotificationPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.last,
  });

  final List<TenantNotification> content;
  final int page;
  final int size;
  final int totalPages;
  final bool last;

  factory TenantNotificationPage.fromJson(Object? value) {
    final json = jsonMap(value);
    if (json == null || json['content'] is! List) {
      throw const FormatException(
        'La respuesta de notificaciones no es paginada.',
      );
    }
    return TenantNotificationPage(
      content: jsonMapList(
        json['content'],
      ).map(TenantNotification.fromJson).toList(growable: false),
      page: jsonInt(json['page']) ?? 0,
      size: jsonInt(json['size']) ?? 20,
      totalPages: jsonInt(json['totalPages']) ?? 0,
      last: json['last'] == true,
    );
  }
}

class TenantNotificationSummary {
  const TenantNotificationSummary(this.unreadCount);

  final int unreadCount;

  factory TenantNotificationSummary.fromJson(Object? value) {
    final json = jsonMap(value);
    if (json == null) {
      throw const FormatException('El resumen de notificaciones no es válido.');
    }
    return TenantNotificationSummary(jsonInt(json['noLeidas']) ?? 0);
  }
}
