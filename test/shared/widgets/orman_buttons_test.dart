import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/app/theme/app_theme.dart';
import 'package:orman/app/theme/orman_semantic_colors.dart';
import 'package:orman/app/theme/orman_theme_kind.dart';
import 'package:orman/shared/widgets/orman_buttons.dart';

void main() {
  testWidgets('danger action uses a tinted red surface and semantic text', (
    tester,
  ) async {
    final theme = AppTheme.forKind(OrmanThemeKind.orman);
    final colors = theme.extension<OrmanSemanticColors>()!;

    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: OrmanActionButton(
            label: 'Dar de baja persona',
            role: OrmanSemanticRole.danger,
            onPressed: _noOp,
          ),
        ),
      ),
    );

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    final states = <WidgetState>{};

    expect(
      button.style!.backgroundColor!.resolve(states),
      colors.surfaceFor(OrmanSemanticRole.danger),
    );
    expect(button.style!.foregroundColor!.resolve(states), colors.dangerText);
  });
}

void _noOp() {}
