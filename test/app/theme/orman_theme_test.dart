import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/app/app.dart';
import 'package:orman/app/theme/app_theme.dart';
import 'package:orman/app/theme/orman_semantic_colors.dart';
import 'package:orman/app/theme/orman_theme_controller.dart';
import 'package:orman/app/theme/orman_theme_kind.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_session_service.dart';
import '../../support/fake_portal_api.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'the controller defaults to ORMAN and persists all theme changes',
    () async {
      final controller = OrmanThemeController();
      expect(controller.theme, OrmanThemeKind.orman);

      await controller.restoreSavedTheme();
      expect(controller.theme, OrmanThemeKind.orman);

      await controller.setTheme(OrmanThemeKind.light);
      expect(controller.theme, OrmanThemeKind.light);
      expect(
        (await SharedPreferences.getInstance()).getString(
          OrmanThemeController.storageKey,
        ),
        'light',
      );

      await controller.setTheme(OrmanThemeKind.dark);
      expect(controller.theme, OrmanThemeKind.dark);
      expect(
        (await SharedPreferences.getInstance()).getString(
          OrmanThemeController.storageKey,
        ),
        'dark',
      );

      final restoredController = OrmanThemeController();
      await restoredController.restoreSavedTheme();
      expect(restoredController.theme, OrmanThemeKind.dark);

      controller.dispose();
      restoredController.dispose();
    },
  );

  test('each theme maps the main semantic roles to its ColorScheme', () {
    final cases = <(OrmanThemeKind, Color, Color, Brightness)>[
      (
        OrmanThemeKind.orman,
        const Color(0xFF000F1F),
        const Color(0xFFD4A94E),
        Brightness.dark,
      ),
      (
        OrmanThemeKind.light,
        const Color(0xFFFFFFFF),
        const Color(0xFFD4A94E),
        Brightness.light,
      ),
      (
        OrmanThemeKind.dark,
        const Color(0xFF080808),
        const Color(0xFFD4A94E),
        Brightness.dark,
      ),
    ];

    for (final (kind, page, accent, brightness) in cases) {
      final theme = AppTheme.forKind(kind);
      final tokens = theme.extension<OrmanSemanticColors>()!;
      expect(tokens.page, page);
      expect(tokens.accent, accent);
      expect(theme.colorScheme.primary, accent);
      expect(theme.colorScheme.surface, tokens.surface);
      expect(theme.colorScheme.error, tokens.danger);
      expect(theme.brightness, brightness);
    }

    final orman = AppTheme.forKind(
      OrmanThemeKind.orman,
    ).extension<OrmanSemanticColors>()!;
    final light = AppTheme.forKind(
      OrmanThemeKind.light,
    ).extension<OrmanSemanticColors>()!;
    final dark = AppTheme.forKind(
      OrmanThemeKind.dark,
    ).extension<OrmanSemanticColors>()!;
    expect(orman.pageGradient.last, const Color(0xFF062238));
    expect(light.pageGradient.last, const Color(0xFFF1F4F7));
    expect(dark.pageGradient.last, const Color(0xFF161616));
    expect(orman.modalGradient, isNotNull);
    expect(light.modalGradient, isNull);
    expect(dark.modalGradient, isNull);
  });

  testWidgets('the selector applies Día and Noche without a dark-mode toggle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      OrmanApp(
        sessionManager: createTestSessionManager(),
        apiClient: createFakePortalApi(),
      ),
    );
    await tester.pumpAndSettle();

    MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.theme!.brightness, Brightness.dark);
    expect(
      app.theme!.extension<OrmanSemanticColors>()!.page,
      const Color(0xFF000F1F),
    );

    await tester.tap(find.text('Día'));
    await tester.pumpAndSettle();
    app = tester.widget(find.byType(MaterialApp));
    expect(app.theme!.brightness, Brightness.light);
    expect(
      app.theme!.extension<OrmanSemanticColors>()!.page,
      const Color(0xFFFFFFFF),
    );

    await tester.tap(find.text('Noche'));
    await tester.pumpAndSettle();
    app = tester.widget(find.byType(MaterialApp));
    expect(app.theme!.brightness, Brightness.dark);
    expect(
      app.theme!.extension<OrmanSemanticColors>()!.page,
      const Color(0xFF080808),
    );
  });
}
