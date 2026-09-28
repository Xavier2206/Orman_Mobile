import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/constants/app_breakpoints.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_theme_extensions.dart';
import '../../../app/theme/orman_theme_controller.dart';
import '../../../app/theme/orman_semantic_colors.dart';
import '../../../core/auth/session_manager.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/orman_buttons.dart';
import '../../../shared/widgets/orman_card.dart';
import '../../../shared/widgets/orman_page_background.dart';
import '../../../shared/widgets/orman_theme_selector.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    required this.sessionManager,
    required this.themeController,
    this.initialMessage,
    super.key,
  });

  final SessionManager sessionManager;
  final OrmanThemeController themeController;
  final String? initialMessage;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _showPassword = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialMessage;
  }

  @override
  void didUpdateWidget(covariant LoginPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMessage != widget.initialMessage &&
        widget.initialMessage != null) {
      _errorMessage = widget.initialMessage;
    }
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await widget.sessionManager.signIn(
        login: _loginController.text.trim(),
        password: _passwordController.text,
      );
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error is ApiException
              ? error.detail
              : 'No se pudo iniciar sesión. Inténtalo nuevamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.ormanColors;

    return OrmanPageBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth <= AppBreakpoints.compact;
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compact ? AppSpacing.x4 : AppSpacing.x6,
                  AppSpacing.x5,
                  compact ? AppSpacing.x4 : AppSpacing.x6,
                  AppSpacing.x6,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: OrmanThemeSelector(
                              controller: widget.themeController,
                            ),
                          ),
                          SizedBox(
                            height: compact ? AppSpacing.x5 : AppSpacing.x8,
                          ),
                          _BrandHeader(
                            titleStyle: theme.textTheme.headlineMedium,
                            mutedStyle: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.x6),
                          OrmanCard(
                            padding: const EdgeInsets.all(AppSpacing.x5),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Iniciar sesión',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.x4),
                                  TextFormField(
                                    key: const Key('login-field'),
                                    controller: _loginController,
                                    autofocus: false,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    keyboardType: TextInputType.text,
                                    maxLength: 30,
                                    buildCounter:
                                        (
                                          context, {
                                          required currentLength,
                                          required isFocused,
                                          required maxLength,
                                        }) => null,
                                    decoration: const InputDecoration(
                                      labelText: 'Usuario',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: _validateLogin,
                                    onChanged: (_) => _clearError(),
                                  ),
                                  const SizedBox(height: AppSpacing.x3),
                                  TextFormField(
                                    key: const Key('password-field'),
                                    controller: _passwordController,
                                    textInputAction: TextInputAction.done,
                                    keyboardType: TextInputType.visiblePassword,
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    obscureText: !_showPassword,
                                    maxLength: 72,
                                    buildCounter:
                                        (
                                          context, {
                                          required currentLength,
                                          required isFocused,
                                          required maxLength,
                                        }) => null,
                                    decoration: InputDecoration(
                                      labelText: 'Contraseña',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                      ),
                                      suffixIcon: IconButton(
                                        tooltip: _showPassword
                                            ? 'Ocultar contraseña'
                                            : 'Mostrar contraseña',
                                        onPressed: () => setState(
                                          () => _showPassword = !_showPassword,
                                        ),
                                        icon: Icon(
                                          _showPassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: _validatePassword,
                                    onChanged: (_) => _clearError(),
                                    onFieldSubmitted: (_) => _submit(),
                                  ),
                                  if (_errorMessage != null) ...[
                                    const SizedBox(height: AppSpacing.x4),
                                    _LoginError(message: _errorMessage!),
                                  ],
                                  const SizedBox(height: AppSpacing.x5),
                                  OrmanPrimaryButton(
                                    key: const Key('login-submit'),
                                    label: 'Iniciar sesión',
                                    icon: Icons.login,
                                    isLoading: _isSubmitting,
                                    onPressed: _isSubmitting ? null : _submit,
                                  ),
                                  const SizedBox(height: AppSpacing.x3),
                                  Text(
                                    'Acceso para inquilinos',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
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

  String? _validateLogin(String? value) {
    final login = value?.trim() ?? '';
    if (login.isEmpty) return 'Ingresa tu usuario.';
    if (login.length > 30) return 'El usuario no puede superar 30 caracteres.';
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.trim().isEmpty) return 'Ingresa tu contraseña.';
    if (password.length < 8 || password.length > 72) {
      return 'La contraseña debe tener entre 8 y 72 caracteres.';
    }
    return null;
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.titleStyle, required this.mutedStyle});

  final TextStyle? titleStyle;
  final TextStyle? mutedStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    return Column(
      children: [
        SvgPicture.asset(
          'assets/branding/logo/orman-logo.svg',
          width: 70,
          height: 86,
          fit: BoxFit.contain,
          semanticsLabel: 'Logo ORMAN',
        ),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Bienvenido a ORMAN',
          textAlign: TextAlign.center,
          style: titleStyle?.copyWith(color: colors.text),
        ),
        const SizedBox(height: AppSpacing.x2),
        Text(
          'Administra tus contratos y pagos desde tu dispositivo.',
          textAlign: TextAlign.center,
          style: mutedStyle?.copyWith(color: colors.textMuted),
        ),
      ],
    );
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.ormanColors;
    return Container(
      key: const Key('login-error'),
      decoration: BoxDecoration(
        color: colors.surfaceFor(OrmanSemanticRole.danger),
        border: Border.all(
          color: colors
              .colorFor(OrmanSemanticRole.danger)
              .withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(AppSpacing.x3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: colors.textFor(OrmanSemanticRole.danger),
          ),
          const SizedBox(width: AppSpacing.x2),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textFor(OrmanSemanticRole.danger),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
