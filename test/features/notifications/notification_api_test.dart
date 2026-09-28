import 'package:flutter_test/flutter_test.dart';
import 'package:orman/features/notifications/data/notification_api.dart';

import '../../support/fake_portal_api.dart';

void main() {
  test(
    'notifications page and unread summary parse backend response',
    () async {
      final api = NotificationApi(createFakePortalApi());
      final page = await api.list();
      final summary = await api.getSummary();

      expect(page.content, hasLength(1));
      expect(page.content.single.code, 5);
      expect(page.content.single.referenceType, 'CUOTA');
      expect(page.content.single.referenceId, 88);
      expect(page.content.single.isRead, isFalse);
      expect(summary.unreadCount, 2);
    },
  );

  test('mark-read updates the notification returned by the backend', () async {
    final api = NotificationApi(createFakePortalApi());
    final read = await api.markRead(5);
    expect(read.code, 5);
    expect(read.isRead, isTrue);
  });
}
