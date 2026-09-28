import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme_extensions.dart';
import '../../app/theme/orman_semantic_colors.dart';

/// Badge neutral reutilizable; el texto de negocio lo aporta quien lo usa.
class OrmanStatusBadge extends StatelessWidget {
  const OrmanStatusBadge({
    required this.label,
    this.role = OrmanSemanticRole.neutral,
    super.key,
  });

  final String label;
  final OrmanSemanticRole role;

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    final roleColor = colors.colorFor(role);
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x1,
        ),
        decoration: BoxDecoration(
          color: role == OrmanSemanticRole.neutral
              ? colors.neutralSurface
              : colors.surfaceFor(role),
          border: Border.all(color: roleColor.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: colors.textFor(role)),
        ),
      ),
    );
  }
}
