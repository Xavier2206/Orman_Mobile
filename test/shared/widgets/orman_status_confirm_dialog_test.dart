import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/app/theme/app_theme.dart';
import 'package:orman/app/theme/orman_semantic_colors.dart';
import 'package:orman/app/theme/orman_theme_kind.dart';
import 'package:orman/shared/widgets/orman_buttons.dart';
import 'package:orman/shared/widgets/orman_status_confirm_dialog.dart';

const _title = '¿Dar de baja a esta persona?';
const _subject = 'Juan Pérez';
const _message = 'La persona quedará inactiva y no podrá usar las operaciones.';

void main() {
  testWidgets('shows its content and Cancelar closes the modal', (
    tester,
  ) async {
    await _pumpModal(tester);

    expect(find.text(_title), findsOneWidget);
    expect(find.text(_subject), findsOneWidget);
    expect(find.text(_message), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(find.byType(OrmanStatusConfirmDialog), findsNothing);
  });

  testWidgets('Confirmar calls its callback', (tester) async {
    var confirmations = 0;
    await _pumpModal(tester, onConfirm: () => confirmations++);

    await tester.tap(find.text('Dar de baja'));
    await tester.pumpAndSettle();
    expect(confirmations, 1);
    expect(find.byType(OrmanStatusConfirmDialog), findsOneWidget);
  });

  testWidgets('loading disables both actions and blocks confirmation', (
    tester,
  ) async {
    var confirmations = 0;
    await _pumpModal(tester, isLoading: true, onConfirm: () => confirmations++);

    final action = tester.widget<OrmanActionButton>(
      find.byType(OrmanActionButton),
    );
    final cancel = tester.widget<OrmanSecondaryButton>(
      find.byType(OrmanSecondaryButton),
    );
    expect(action.isLoading, isTrue);
    expect(cancel.onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.text('Dar de baja'), warnIfMissed: false);
    await tester.pump();
    expect(confirmations, 0);
  });

  testWidgets('a pending asynchronous confirmation blocks a second submit', (
    tester,
  ) async {
    final completion = Completer<void>();
    var confirmations = 0;
    await _pumpModal(
      tester,
      onConfirm: () {
        confirmations++;
        return completion.future;
      },
    );

    await tester.tap(find.text('Dar de baja'));
    await tester.pump();
    await tester.tap(find.text('Dar de baja'), warnIfMissed: false);
    await tester.pump();
    expect(confirmations, 1);

    completion.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('the barrier does not dismiss the modal', (tester) async {
    await _pumpModal(tester);

    await tester.tapAt(const Offset(2, 2));
    await tester.pumpAndSettle();
    expect(find.byType(OrmanStatusConfirmDialog), findsOneWidget);
  });

  testWidgets('390 px stacks full-width actions without overflow', (
    tester,
  ) async {
    await _pumpModal(tester, size: const Size(390, 800));

    final cancel = tester.getRect(find.byType(OrmanSecondaryButton));
    final confirm = tester.getRect(find.byType(OrmanActionButton));
    expect(confirm.top, greaterThan(cancel.bottom));
    expect(confirm.width, closeTo(cancel.width, 0.1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide layout keeps the panel at or below 512 px', (tester) async {
    await _pumpModal(tester, size: const Size(1024, 800));

    expect(
      tester
          .getSize(find.byKey(const ValueKey('orman-status-dialog-panel')))
          .width,
      lessThanOrEqualTo(512),
    );
  });

  testWidgets('the title and actions have accessible semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _pumpModal(tester);

    expect(find.bySemanticsLabel(_title), findsWidgets);
    expect(find.bySemanticsLabel(_subject), findsOneWidget);
    expect(find.bySemanticsLabel(_message), findsOneWidget);
    expect(find.bySemanticsLabel('Cancelar'), findsOneWidget);
    expect(find.bySemanticsLabel('Dar de baja'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('Escape closes the modal when it is idle', (tester) async {
    await _pumpModal(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(OrmanStatusConfirmDialog), findsNothing);
  });

  testWidgets('Android Back closes the modal when it is idle', (tester) async {
    await _pumpModal(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(OrmanStatusConfirmDialog), findsNothing);
  });

  testWidgets('Android Back is blocked while the modal is loading', (
    tester,
  ) async {
    await _pumpModal(tester, isLoading: true);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(OrmanStatusConfirmDialog), findsOneWidget);
  });
}

Future<void> _pumpModal(
  WidgetTester tester, {
  Size size = const Size(390, 800),
  bool isLoading = false,
  FutureOr<void> Function()? onConfirm,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.forKind(OrmanThemeKind.orman),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                unawaited(
                  OrmanStatusConfirmDialog.show(
                    context: context,
                    title: _title,
                    subject: _subject,
                    message: _message,
                    icon: Icons.person_off,
                    role: OrmanSemanticRole.danger,
                    confirmLabel: 'Dar de baja',
                    isLoading: isLoading,
                    onConfirm: onConfirm ?? () {},
                  ),
                );
              },
              child: const Text('Abrir modal'),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Abrir modal'));
  if (isLoading) {
    await tester.pump();
  } else {
    await tester.pumpAndSettle();
  }
}
