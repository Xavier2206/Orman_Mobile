import '../../../core/network/api_client.dart';
import '../../../core/network/json_readers.dart';
import '../models/tenant_notification.dart';

class NotificationApi {
  const NotificationApi(this._http);

  final ApiClient _http;

  Future<TenantNotificationSummary> getSummary() async =>
      TenantNotificationSummary.fromJson(
        await _http.getJson('api/v1/notificaciones/resumen'),
      );

  Future<TenantNotificationPage> list({int page = 0, int size = 20}) async =>
      TenantNotificationPage.fromJson(
        await _http.getJson(
          'api/v1/notificaciones',
          queryParameters: {'page': page, 'size': size},
        ),
      );

  Future<TenantNotification> get(int code) async {
    final json = jsonMap(await _http.getJson('api/v1/notificaciones/$code'));
    if (json == null) {
      throw const FormatException('La notificación no es válida.');
    }
    return TenantNotification.fromJson(json);
  }

  Future<TenantNotification> markRead(int code) async {
    final json = jsonMap(
      await _http.patchEmpty('api/v1/notificaciones/$code/leer'),
    );
    if (json == null) {
      throw const FormatException(
        'La respuesta al marcar lectura no es válida.',
      );
    }
    return TenantNotification.fromJson(json);
  }
}
