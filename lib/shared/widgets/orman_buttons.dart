import 'package:flutter/material.dart';

import '../../app/theme/app_radius.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme_extensions.dart';
import '../../app/theme/orman_semantic_colors.dart';

/// Botón principal ORMAN con altura estable durante su estado de carga.
class OrmanPrimaryButton extends StatelessWidget {
  const OrmanPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: isLoading,
      value: isLoading ? 'Procesando' : null,
      child: SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: _ButtonContents(
            label: label,
            icon: icon,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }
}

/// Botón secundario con superficie y borde semánticos del tema actual.
class OrmanSecondaryButton extends StatelessWidget {
  const OrmanSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: isLoading,
      value: isLoading ? 'Procesando' : null,
      child: SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: _ButtonContents(
            label: label,
            icon: icon,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }
}

/// Acción semántica con fondo tintado y borde del rol correspondiente.
class OrmanActionButton extends StatelessWidget {
  const OrmanActionButton({
    required this.label,
    required this.role,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final OrmanSemanticRole role;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    final roleColor = colors.colorFor(role);
    final roleText = colors.textFor(role);
    return Semantics(
      liveRegion: isLoading,
      value: isLoading ? 'Procesando' : null,
      child: SizedBox(
        height: 44,
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.surfaceFor(role),
            foregroundColor: roleText,
            disabledBackgroundColor: colors
                .surfaceFor(role)
                .withValues(alpha: 0.55),
            disabledForegroundColor: roleText.withValues(alpha: 0.64),
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
            elevation: 0,
            textStyle: Theme.of(context).textTheme.labelLarge,
            side: BorderSide(color: roleColor.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            overlayColor: colors.focus.withValues(alpha: 0.16),
          ),
          child: _ButtonContents(
            label: label,
            icon: icon,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }
}

class _ButtonContents extends StatelessWidget {
  const _ButtonContents({
    required this.label,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox.square(
            dimension: 20,
            child: Center(
              child: SizedBox.square(
                dimension: 16,
                child: ExcludeSemantics(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        if (isLoading || icon != null) const SizedBox(width: AppSpacing.x2),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}
