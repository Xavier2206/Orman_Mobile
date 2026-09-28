import 'package:flutter/material.dart';

import 'orman_semantic_colors.dart';

/// Acceso corto a los tokens semánticos del tema actual.
extension OrmanThemeContext on BuildContext {
  OrmanSemanticColors get ormanColors =>
      Theme.of(this).extension<OrmanSemanticColors>()!;
}
