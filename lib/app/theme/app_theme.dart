import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';
import 'orman_semantic_colors.dart';
import 'orman_theme_kind.dart';

/// Construye el ThemeData completo a partir de los tokens semánticos.
abstract final class AppTheme {
  static ThemeData forKind(OrmanThemeKind kind) {
    final colors = _colorsFor(kind);
    final brightness = kind == OrmanThemeKind.light
        ? Brightness.light
        : Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.accentContrast,
      secondary: colors.accent,
      onSecondary: colors.accentContrast,
      error: colors.danger,
      onError: Colors.white,
      surface: colors.surface,
      onSurface: colors.text,
      outline: colors.fieldBorder,
      outlineVariant: colors.border,
      surfaceContainerHighest: colors.card,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.page,
      dividerColor: colors.border,
      focusColor: colors.focus.withValues(alpha: 0.18),
      textTheme: AppTypography.textTheme.apply(
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
      extensions: <ThemeExtension<dynamic>>[colors],
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        constraints: const BoxConstraints(minHeight: 44),
        fillColor: colors.field,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x3,
          vertical: AppSpacing.x2 + AppSpacing.x1,
        ),
        labelStyle: TextStyle(
          color: colors.textMuted,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: TextStyle(
          color: colors.focus,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: colors.textMuted),
        border: _inputBorder(colors.fieldBorder),
        enabledBorder: _inputBorder(colors.fieldBorder),
        focusedBorder: _inputBorder(colors.focus, width: 1.5),
        errorBorder: _inputBorder(colors.danger),
        focusedErrorBorder: _inputBorder(colors.danger, width: 1.5),
      ),
      cardTheme: CardThemeData(
        color: colors.card,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        elevation: 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: colors.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.accent,
          foregroundColor: colors.accentContrast,
          disabledBackgroundColor: colors.accent.withValues(alpha: 0.38),
          disabledForegroundColor: colors.accentContrast.withValues(
            alpha: 0.64,
          ),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
          elevation: 0,
          textStyle: AppTypography.textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          overlayColor: colors.accentHover.withValues(alpha: 0.18),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: colors.surface,
          foregroundColor: colors.text,
          disabledForegroundColor: colors.textMuted.withValues(alpha: 0.6),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
          textStyle: AppTypography.textTheme.labelLarge,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          overlayColor: colors.cardHover,
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        borderSide: BorderSide(color: color, width: width),
      );

  static OrmanSemanticColors _colorsFor(OrmanThemeKind kind) => switch (kind) {
    OrmanThemeKind.orman => const OrmanSemanticColors(
      page: Color(0xFF000F1F),
      pageGradient: [Color(0xFF000F1F), Color(0xFF021427), Color(0xFF062238)],
      surface: Color(0xFF021427),
      card: Color(0xFF062238),
      cardHover: Color(0xFF0A2B45),
      field: Color(0x06FFFFFF),
      fieldBorder: Color(0x40E7EDF3),
      text: Color(0xFFE7EDF3),
      textMuted: Color(0xFFAEBBC7),
      accent: AppColors.brandAccent,
      accentText: AppColors.brandAccent,
      accentHover: Color(0xFFE0BB68),
      accentContrast: Color(0xFF000F1F),
      border: Color(0x40D4A94E),
      overlay: Color(0xB8000F1F),
      success: AppColors.brandSuccess,
      warning: AppColors.brandWarning,
      info: AppColors.brandInfo,
      danger: AppColors.brandDanger,
      focus: AppColors.brandAccent,
      modalBackground: Color(0xFF000F1F),
      modalGradient: [Color(0xFF000F1F), Color(0xFF021427), Color(0xFF062238)],
      modalBorder: Color(0xB3D4A94E),
      modalInnerBorder: Color(0x33D4A94E),
      modalShadow: Color(0x6B000000),
      successText: Color(0xFF4ADE80),
      warningText: Color(0xFFFBBF24),
      infoText: Color(0xFF7DD3FC),
      dangerText: Color(0xFFF87171),
      neutral: Color(0xFFAEBBC7),
      neutralSurface: Color(0x14FFFFFF),
    ),
    OrmanThemeKind.light => const OrmanSemanticColors(
      page: Color(0xFFFFFFFF),
      pageGradient: [Color(0xFFFAFCFE), Color(0xFFF6F8FA), Color(0xFFF1F4F7)],
      surface: Color(0xFFF4F6F8),
      card: Color(0xFFFFFFFF),
      cardHover: Color(0xFFF8FAFC),
      field: Color(0xFFF8FAFC),
      fieldBorder: Color(0xFFC2CBD4),
      text: Color(0xFF000F1F),
      textMuted: Color(0xFF52606D),
      accent: AppColors.brandAccent,
      accentText: Color(0xFF80601B),
      accentHover: Color(0xFFBF9134),
      accentContrast: Color(0xFF000F1F),
      border: Color(0xFFD9E0E6),
      overlay: Color(0x29000F1F),
      success: AppColors.brandSuccess,
      warning: Color(0xFFB45309),
      info: Color(0xFF0369A1),
      danger: AppColors.brandDanger,
      focus: AppColors.brandAccent,
      modalBackground: Color(0xFFFFFFFF),
      modalGradient: null,
      modalBorder: Color(0xFFD9E0E6),
      modalInnerBorder: Color(0x66D4A94E),
      modalShadow: Color(0x26000F1F),
      successText: Color(0xFF166534),
      warningText: Color(0xFF92400E),
      infoText: Color(0xFF075985),
      dangerText: Color(0xFFB91C1C),
      neutral: Color(0xFF52606D),
      neutralSurface: Color(0xFFF1F4F7),
    ),
    OrmanThemeKind.dark => const OrmanSemanticColors(
      page: Color(0xFF080808),
      pageGradient: [Color(0xFF080808), Color(0xFF0F0F0F), Color(0xFF161616)],
      surface: Color(0xFF111111),
      card: Color(0xFF191919),
      cardHover: Color(0xFF232323),
      field: Color(0x06FFFFFF),
      fieldBorder: Color(0x40F5F5F5),
      text: Color(0xFFF5F5F5),
      textMuted: Color(0xFFB8B8B8),
      accent: AppColors.brandAccent,
      accentText: AppColors.brandAccent,
      accentHover: Color(0xFFE0BB68),
      accentContrast: Color(0xFF080808),
      border: Color(0x38D4A94E),
      overlay: Color(0xB8000000),
      success: AppColors.brandSuccess,
      warning: AppColors.brandWarning,
      info: AppColors.brandInfo,
      danger: AppColors.brandDanger,
      focus: AppColors.brandAccent,
      modalBackground: Color(0xFF111111),
      modalGradient: null,
      modalBorder: Color(0x38D4A94E),
      modalInnerBorder: Color(0x29D4A94E),
      modalShadow: Color(0x99000000),
      successText: Color(0xFF4ADE80),
      warningText: Color(0xFFFBBF24),
      infoText: Color(0xFF7DD3FC),
      dangerText: Color(0xFFF87171),
      neutral: Color(0xFFB8B8B8),
      neutralSurface: Color(0xFF232323),
    ),
  };
}
