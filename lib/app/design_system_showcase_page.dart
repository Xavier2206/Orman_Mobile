import 'package:flutter/material.dart';

import '../shared/widgets/orman_buttons.dart';
import '../shared/widgets/orman_card.dart';
import '../shared/widgets/orman_page_background.dart';
import '../shared/widgets/orman_status_badge.dart';
import '../shared/widgets/orman_status_confirm_dialog.dart';
import '../shared/widgets/orman_theme_selector.dart';
import 'constants/app_breakpoints.dart';
import 'theme/app_spacing.dart';
import 'theme/app_theme_extensions.dart';
import 'theme/orman_semantic_colors.dart';
import 'theme/orman_theme_controller.dart';

/// Showcase temporal para revisar el design system antes de crear Login.
class DesignSystemShowcasePage extends StatelessWidget {
  const DesignSystemShowcasePage({required this.themeController, super.key});

  final OrmanThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return OrmanPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding =
                  constraints.maxWidth <= AppBreakpoints.compact
                  ? AppSpacing.x4
                  : AppSpacing.x6;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.x5,
                  horizontalPadding,
                  AppSpacing.x8,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _PageHeader(themeController: themeController),
                        const SizedBox(height: AppSpacing.x6),
                        _ShowcaseGrid(
                          children: [
                            _TypographyCard(),
                            const _ColorRolesCard(),
                            const _ButtonsCard(),
                            const _InputCard(),
                            const _SurfacesCard(),
                            _StatusDialogCard(onOpen: _openStatusDialog),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openStatusDialog(
    BuildContext context, {
    required bool activate,
  }) async {
    final result = await OrmanStatusConfirmDialog.show(
      context: context,
      title: activate
          ? '¿Reactivar a esta persona?'
          : '¿Dar de baja a esta persona?',
      subject: 'Juan Pérez',
      message: activate
          ? 'La persona volverá a estado activo y podrá continuar siendo gestionada normalmente en el sistema.'
          : 'La persona quedará inactiva y no podrá utilizar las operaciones asociadas mientras permanezca en este estado.',
      icon: activate ? Icons.restore : Icons.person_off,
      role: activate ? OrmanSemanticRole.success : OrmanSemanticRole.danger,
      confirmLabel: activate ? 'Reactivar persona' : 'Dar de baja',
      onConfirm: () => Navigator.of(context).pop(true),
    );

    if (context.mounted && result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate
                ? 'Demostración: persona reactivada.'
                : 'Demostración: persona dada de baja.',
          ),
        ),
      );
    }
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.themeController});

  final OrmanThemeController themeController;

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.diamond_outlined,
                color: colors.accent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.x3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ORMAN',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.accentText,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Sistema visual',
                    style: Theme.of(
                      context,
                    ).textTheme.headlineMedium?.copyWith(color: colors.text),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x3),
        Text(
          'Showcase temporal para validar el tema y los componentes antes de construir el portal móvil.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colors.textMuted),
        ),
        const SizedBox(height: AppSpacing.x4),
        OrmanThemeSelector(controller: themeController),
      ],
    );
  }
}

class _ShowcaseGrid extends StatelessWidget {
  const _ShowcaseGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= AppBreakpoints.wide
            ? 3
            : constraints.maxWidth >= AppBreakpoints.tablet
            ? 2
            : 1;
        const gap = AppSpacing.x4;
        final itemWidth =
            (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _TypographyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;
    return OrmanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tipografía', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.x3),
          Text('Título de página', style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpacing.x1),
          Text('Título de sección', style: theme.textTheme.titleLarge),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Texto principal con la fuente nativa de Flutter.',
            style: theme.textTheme.bodyMedium,
          ),
          Text(
            'Texto secundario y auxiliar.',
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ColorRolesCard extends StatelessWidget {
  const _ColorRolesCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    final theme = Theme.of(context);
    final swatches = <(String, Color)>[
      ('Página', colors.page),
      ('Superficie', colors.surface),
      ('Tarjeta', colors.card),
      ('Acento', colors.accent),
      ('Éxito', colors.success),
      ('Aviso', colors.warning),
      ('Información', colors.info),
      ('Peligro', colors.danger),
    ];
    return OrmanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tokens semánticos', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: [
              for (final (label, color) in swatches)
                _ColorSwatch(label: label, color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
        ),
        const SizedBox(width: AppSpacing.x1),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ButtonsCard extends StatelessWidget {
  const _ButtonsCard();

  @override
  Widget build(BuildContext context) {
    return OrmanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Botones', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.x3),
          const OrmanPrimaryButton(label: 'Acción principal', onPressed: _noop),
          const SizedBox(height: AppSpacing.x2),
          const OrmanSecondaryButton(
            label: 'Acción secundaria',
            onPressed: _noop,
          ),
          const SizedBox(height: AppSpacing.x2),
          const OrmanActionButton(
            label: 'Acción positiva',
            role: OrmanSemanticRole.success,
            icon: Icons.check,
            onPressed: _noop,
          ),
          const SizedBox(height: AppSpacing.x2),
          const OrmanActionButton(
            label: 'Acción de peligro',
            role: OrmanSemanticRole.danger,
            icon: Icons.delete_outline,
            onPressed: _noop,
          ),
        ],
      ),
    );
  }

  static void _noop() {}
}

class _InputCard extends StatelessWidget {
  const _InputCard();

  @override
  Widget build(BuildContext context) {
    return OrmanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Campos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.x3),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Nombre de persona',
              hintText: 'Escribe un nombre',
              prefixIcon: Icon(Icons.person_outline, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          const TextField(
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              hintText: 'nombre@ejemplo.com',
              prefixIcon: Icon(Icons.mail_outline, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfacesCard extends StatelessWidget {
  const _SurfacesCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    return OrmanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estados y superficies',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x3),
          Wrap(
            spacing: AppSpacing.x2,
            runSpacing: AppSpacing.x2,
            children: const [
              OrmanStatusBadge(
                label: 'VIGENTE',
                role: OrmanSemanticRole.success,
              ),
              OrmanStatusBadge(
                label: 'PENDIENTE',
                role: OrmanSemanticRole.warning,
              ),
              OrmanStatusBadge(
                label: 'INFORMACIÓN',
                role: OrmanSemanticRole.info,
              ),
              OrmanStatusBadge(
                label: 'ANULADA',
                role: OrmanSemanticRole.danger,
              ),
              OrmanStatusBadge(label: 'NEUTRAL'),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.x3),
            decoration: BoxDecoration(
              color: colors.cardHover,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Superficie elevada',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDialogCard extends StatelessWidget {
  const _StatusDialogCard({required this.onOpen});

  final Future<void> Function(BuildContext context, {required bool activate})
  onOpen;

  @override
  Widget build(BuildContext context) {
    return OrmanCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Modal de confirmación',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            'Diálogo temporal inspirado en la confirmación de estado de Persona en Angular.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.ormanColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.x3),
          OrmanSecondaryButton(
            label: 'Probar modal ORMAN',
            icon: Icons.open_in_new,
            onPressed: () => onOpen(context, activate: false),
          ),
          const SizedBox(height: AppSpacing.x2),
          OrmanActionButton(
            label: 'Dar de baja persona',
            role: OrmanSemanticRole.danger,
            icon: Icons.person_off,
            onPressed: () => onOpen(context, activate: false),
          ),
          const SizedBox(height: AppSpacing.x2),
          OrmanActionButton(
            label: 'Reactivar persona',
            role: OrmanSemanticRole.success,
            icon: Icons.restore,
            onPressed: () => onOpen(context, activate: true),
          ),
        ],
      ),
    );
  }
}
