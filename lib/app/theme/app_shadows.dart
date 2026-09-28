import 'package:flutter/material.dart';

import 'orman_semantic_colors.dart';

/// Sombras reutilizables; el modal usa el color previsto por cada tema.
abstract final class AppShadows {
  static const List<BoxShadow> small = [
    BoxShadow(color: Color(0x2E000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x38000000), blurRadius: 24, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> large = [
    BoxShadow(color: Color(0x47000000), blurRadius: 48, offset: Offset(0, 18)),
  ];

  static List<BoxShadow> modal(OrmanSemanticColors colors) => [
    BoxShadow(
      color: colors.modalShadow,
      blurRadius: 60,
      offset: const Offset(0, 24),
    ),
  ];
}
