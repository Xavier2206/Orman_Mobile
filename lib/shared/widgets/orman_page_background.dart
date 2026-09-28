import 'package:flutter/material.dart';

import '../../app/theme/app_theme_extensions.dart';

/// Fondo de página que sigue el gradiente definido por el tema activo.
class OrmanPageBackground extends StatelessWidget {
  const OrmanPageBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors.pageGradient,
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: child,
      ),
    );
  }
}
