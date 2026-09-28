import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

/// Superficie común para el contenido del design system.
class OrmanCard extends StatelessWidget {
  const OrmanCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.x4),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
