import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/orman_theme_controller.dart';
import '../../app/theme/orman_theme_kind.dart';

/// Selector compacto que aplica los tres temas sin añadir un gestor global.
class OrmanThemeSelector extends StatelessWidget {
  const OrmanThemeSelector({required this.controller, super.key});

  final OrmanThemeController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tema visual',
      child: SegmentedButton<OrmanThemeKind>(
        showSelectedIcon: false,
        segments: OrmanThemeKind.values
            .map(
              (kind) => ButtonSegment<OrmanThemeKind>(
                value: kind,
                label: Text(kind.label),
              ),
            )
            .toList(growable: false),
        selected: <OrmanThemeKind>{controller.theme},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            unawaited(controller.setTheme(selection.first));
          }
        },
      ),
    );
  }
}
