import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants/app_breakpoints.dart';
import '../../app/theme/app_radius.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_theme_extensions.dart';
import '../../app/theme/orman_semantic_colors.dart';
import 'orman_buttons.dart';

/// Confirmación genérica con la composición visual del modal de Personas web.
class OrmanStatusConfirmDialog extends StatefulWidget {
  const OrmanStatusConfirmDialog({
    required this.title,
    required this.subject,
    required this.message,
    required this.icon,
    required this.role,
    required this.confirmLabel,
    required this.onConfirm,
    this.cancelLabel = 'Cancelar',
    this.loadingLabel = 'Procesando...',
    this.failureMessage = 'No se pudo completar la acción. Inténtalo de nuevo.',
    this.isLoading = false,
    super.key,
  });

  final String title;
  final String subject;
  final String message;
  final IconData icon;
  final OrmanSemanticRole role;
  final String confirmLabel;
  final String cancelLabel;
  final String loadingLabel;
  final String failureMessage;
  final bool isLoading;
  final FutureOr<void> Function() onConfirm;

  /// Presenta el diálogo sin transición custom y sin cierre por backdrop.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String subject,
    required String message,
    required IconData icon,
    required OrmanSemanticRole role,
    required String confirmLabel,
    required FutureOr<void> Function() onConfirm,
    String cancelLabel = 'Cancelar',
    String loadingLabel = 'Procesando...',
    String failureMessage =
        'No se pudo completar la acción. Inténtalo de nuevo.',
    bool isLoading = false,
  }) {
    final colors = Theme.of(context).extension<OrmanSemanticColors>()!;
    final navigator = Navigator.of(context, rootNavigator: true);
    final capturedThemes = InheritedTheme.capture(
      from: context,
      to: navigator.context,
    );
    return navigator.push<bool>(
      RawDialogRoute<bool>(
        pageBuilder: (dialogContext, animation, secondaryAnimation) =>
            capturedThemes.wrap(
              SafeArea(
                child: OrmanStatusConfirmDialog(
                  title: title,
                  subject: subject,
                  message: message,
                  icon: icon,
                  role: role,
                  confirmLabel: confirmLabel,
                  cancelLabel: cancelLabel,
                  loadingLabel: loadingLabel,
                  failureMessage: failureMessage,
                  isLoading: isLoading,
                  onConfirm: onConfirm,
                ),
              ),
            ),
        barrierDismissible: false,
        barrierColor: colors.overlay,
        barrierLabel: MaterialLocalizations.of(
          context,
        ).modalBarrierDismissLabel,
        traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
        requestFocus: true,
        transitionDuration: Duration.zero,
        transitionBuilder: (context, animation, secondaryAnimation, child) =>
            child,
      ),
    );
  }

  @override
  State<OrmanStatusConfirmDialog> createState() =>
      _OrmanStatusConfirmDialogState();
}

class _OrmanStatusConfirmDialogState extends State<OrmanStatusConfirmDialog> {
  bool _localLoading = false;
  String? _failure;

  bool get _isBusy => widget.isLoading || _localLoading;

  Future<void> _confirm() async {
    if (_isBusy) return;
    setState(() {
      _localLoading = true;
      _failure = null;
    });
    try {
      await widget.onConfirm();
    } on Object {
      if (mounted) setState(() => _failure = widget.failureMessage);
    } finally {
      if (mounted) setState(() => _localLoading = false);
    }
  }

  void _cancel() {
    if (_isBusy) return;
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    final roleColor = colors.colorFor(widget.role);
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) {
              if (!_isBusy) Navigator.of(context).pop(false);
              return null;
            },
          ),
        },
        child: PopScope<Object?>(
          canPop: !_isBusy,
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            scopesRoute: true,
            namesRoute: true,
            label: widget.title,
            hint: widget.message,
            value: _isBusy ? widget.loadingLabel : null,
            liveRegion: _isBusy,
            child: Dialog(
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              constraints: BoxConstraints(
                maxWidth: 512,
                maxHeight: math.max(160, screenHeight - AppSpacing.x6 * 2),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x4,
                vertical: AppSpacing.x3,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact =
                      constraints.maxWidth <= AppBreakpoints.compact;
                  final horizontalPadding = compact
                      ? AppSpacing.x4
                      : AppSpacing.x6;
                  return ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 512,
                      maxHeight: math.max(
                        160,
                        screenHeight - AppSpacing.x6 * 2,
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.modalBackground,
                          gradient: colors.modalGradient == null
                              ? null
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: colors.modalGradient!,
                                ),
                          border: Border.all(color: colors.modalBorder),
                          borderRadius: BorderRadius.circular(AppRadius.large),
                          boxShadow: AppShadows.modal(colors),
                        ),
                        key: const ValueKey<String>(
                          'orman-status-dialog-panel',
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            border: Border.all(color: colors.modalInnerBorder),
                            borderRadius: BorderRadius.circular(
                              AppRadius.large - 1,
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: FocusTraversalGroup(
                              policy: OrderedTraversalPolicy(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeader(
                                    context,
                                    colors: colors,
                                    roleColor: roleColor,
                                    horizontalPadding: horizontalPadding,
                                  ),
                                  _buildBody(
                                    context,
                                    colors: colors,
                                    horizontalPadding: horizontalPadding,
                                  ),
                                  _buildFooter(
                                    context,
                                    colors: colors,
                                    compact: compact,
                                    horizontalPadding: horizontalPadding,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required OrmanSemanticColors colors,
    required Color roleColor,
    required double horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.x5,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surfaceFor(widget.role),
              border: Border.all(color: roleColor.withValues(alpha: 0.55)),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 26, color: roleColor),
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: colors.text,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required OrmanSemanticColors colors,
    required double horizontalPadding,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.x4,
        left: horizontalPadding,
        right: horizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.subject,
            semanticsLabel: widget.subject,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            widget.message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colors.textMuted,
              height: 1.5,
            ),
          ),
          if (_failure case final failure?) ...[
            const SizedBox(height: AppSpacing.x3),
            Semantics(
              liveRegion: true,
              label: failure,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.x3),
                decoration: BoxDecoration(
                  color: colors.surfaceFor(OrmanSemanticRole.danger),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(
                    color: colors.danger.withValues(alpha: 0.45),
                  ),
                ),
                child: Text(
                  failure,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textFor(OrmanSemanticRole.danger),
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter(
    BuildContext context, {
    required OrmanSemanticColors colors,
    required bool compact,
    required double horizontalPadding,
  }) {
    final cancelButton = FocusTraversalOrder(
      order: const NumericFocusOrder(1),
      child: Focus(
        autofocus: true,
        child: OrmanSecondaryButton(
          label: widget.cancelLabel,
          onPressed: _isBusy ? null : _cancel,
        ),
      ),
    );
    final confirmButton = FocusTraversalOrder(
      order: const NumericFocusOrder(2),
      child: OrmanActionButton(
        label: widget.confirmLabel,
        role: widget.role,
        icon: widget.icon,
        onPressed: _confirm,
        isLoading: _isBusy,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.x5),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.x4,
        horizontalPadding,
        AppSpacing.x5,
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: double.infinity, child: cancelButton),
                const SizedBox(height: AppSpacing.x3),
                SizedBox(width: double.infinity, child: confirmButton),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                cancelButton,
                const SizedBox(width: AppSpacing.x3),
                confirmButton,
              ],
            ),
    );
  }
}
