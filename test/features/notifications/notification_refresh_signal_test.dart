import 'package:flutter_test/flutter_test.dart';
import 'package:orman/features/notifications/data/notification_refresh_signal.dart';

void main() {
  test(
    'resume requests one throttled refresh for an authenticated session',
    () {
      var now = DateTime(2026, 9, 29);
      final signal = NotificationRefreshSignal(clock: () => now);
      addTearDown(signal.dispose);
      var refreshes = 0;
      signal.addListener(() => refreshes++);

      expect(signal.onAppResumed, returnsNormally);
      expect(refreshes, 0);

      signal.onAuthenticated();
      signal.onAppResumed();
      expect(refreshes, 1);

      now = now.add(const Duration(seconds: 1));
      signal.onAppResumed();
      expect(refreshes, 1);

      now = now.add(const Duration(seconds: 2));
      signal.onAppResumed();
      expect(refreshes, 2);
    },
  );

  test(
    'logout suppresses resume refresh until a new session authenticates',
    () {
      final signal = NotificationRefreshSignal();
      addTearDown(signal.dispose);
      var refreshes = 0;
      signal.addListener(() => refreshes++);

      signal.onAuthenticated();
      signal.requestRefresh();
      signal.onSigningOut();
      signal.onAppResumed();

      expect(refreshes, 1);

      signal.onAuthenticated();
      signal.onAppResumed();
      expect(refreshes, 2);
    },
  );
}
