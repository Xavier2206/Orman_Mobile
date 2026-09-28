import 'package:flutter/material.dart';

/// Roles semánticos disponibles para badges y acciones.
enum OrmanSemanticRole { success, warning, info, danger, neutral }

/// Tokens de color con significado de producto, independientes de la paleta.
@immutable
class OrmanSemanticColors extends ThemeExtension<OrmanSemanticColors> {
  const OrmanSemanticColors({
    required this.page,
    required this.pageGradient,
    required this.surface,
    required this.card,
    required this.cardHover,
    required this.field,
    required this.fieldBorder,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentText,
    required this.accentHover,
    required this.accentContrast,
    required this.border,
    required this.overlay,
    required this.success,
    required this.warning,
    required this.info,
    required this.danger,
    required this.focus,
    required this.modalBackground,
    required this.modalGradient,
    required this.modalBorder,
    required this.modalInnerBorder,
    required this.modalShadow,
    required this.successText,
    required this.warningText,
    required this.infoText,
    required this.dangerText,
    required this.neutral,
    required this.neutralSurface,
  });

  final Color page;
  final List<Color> pageGradient;
  final Color surface;
  final Color card;
  final Color cardHover;
  final Color field;
  final Color fieldBorder;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color accentText;
  final Color accentHover;
  final Color accentContrast;
  final Color border;
  final Color overlay;
  final Color success;
  final Color warning;
  final Color info;
  final Color danger;
  final Color focus;
  final Color modalBackground;
  final List<Color>? modalGradient;
  final Color modalBorder;
  final Color modalInnerBorder;
  final Color modalShadow;
  final Color successText;
  final Color warningText;
  final Color infoText;
  final Color dangerText;
  final Color neutral;
  final Color neutralSurface;

  Color colorFor(OrmanSemanticRole role) => switch (role) {
    OrmanSemanticRole.success => success,
    OrmanSemanticRole.warning => warning,
    OrmanSemanticRole.info => info,
    OrmanSemanticRole.danger => danger,
    OrmanSemanticRole.neutral => neutral,
  };

  Color textFor(OrmanSemanticRole role) => switch (role) {
    OrmanSemanticRole.success => successText,
    OrmanSemanticRole.warning => warningText,
    OrmanSemanticRole.info => infoText,
    OrmanSemanticRole.danger => dangerText,
    OrmanSemanticRole.neutral => neutral,
  };

  Color surfaceFor(OrmanSemanticRole role) =>
      colorFor(role).withValues(alpha: 0.12);

  @override
  OrmanSemanticColors copyWith({
    Color? page,
    List<Color>? pageGradient,
    Color? surface,
    Color? card,
    Color? cardHover,
    Color? field,
    Color? fieldBorder,
    Color? text,
    Color? textMuted,
    Color? accent,
    Color? accentText,
    Color? accentHover,
    Color? accentContrast,
    Color? border,
    Color? overlay,
    Color? success,
    Color? warning,
    Color? info,
    Color? danger,
    Color? focus,
    Color? modalBackground,
    List<Color>? modalGradient,
    Color? modalBorder,
    Color? modalInnerBorder,
    Color? modalShadow,
    Color? successText,
    Color? warningText,
    Color? infoText,
    Color? dangerText,
    Color? neutral,
    Color? neutralSurface,
  }) => OrmanSemanticColors(
    page: page ?? this.page,
    pageGradient: pageGradient ?? this.pageGradient,
    surface: surface ?? this.surface,
    card: card ?? this.card,
    cardHover: cardHover ?? this.cardHover,
    field: field ?? this.field,
    fieldBorder: fieldBorder ?? this.fieldBorder,
    text: text ?? this.text,
    textMuted: textMuted ?? this.textMuted,
    accent: accent ?? this.accent,
    accentText: accentText ?? this.accentText,
    accentHover: accentHover ?? this.accentHover,
    accentContrast: accentContrast ?? this.accentContrast,
    border: border ?? this.border,
    overlay: overlay ?? this.overlay,
    success: success ?? this.success,
    warning: warning ?? this.warning,
    info: info ?? this.info,
    danger: danger ?? this.danger,
    focus: focus ?? this.focus,
    modalBackground: modalBackground ?? this.modalBackground,
    modalGradient: modalGradient ?? this.modalGradient,
    modalBorder: modalBorder ?? this.modalBorder,
    modalInnerBorder: modalInnerBorder ?? this.modalInnerBorder,
    modalShadow: modalShadow ?? this.modalShadow,
    successText: successText ?? this.successText,
    warningText: warningText ?? this.warningText,
    infoText: infoText ?? this.infoText,
    dangerText: dangerText ?? this.dangerText,
    neutral: neutral ?? this.neutral,
    neutralSurface: neutralSurface ?? this.neutralSurface,
  );

  @override
  OrmanSemanticColors lerp(
    covariant ThemeExtension<OrmanSemanticColors>? other,
    double t,
  ) {
    if (other is! OrmanSemanticColors) return this;
    return OrmanSemanticColors(
      page: Color.lerp(page, other.page, t)!,
      pageGradient: _lerpColors(pageGradient, other.pageGradient, t),
      surface: Color.lerp(surface, other.surface, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardHover: Color.lerp(cardHover, other.cardHover, t)!,
      field: Color.lerp(field, other.field, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentText: Color.lerp(accentText, other.accentText, t)!,
      accentHover: Color.lerp(accentHover, other.accentHover, t)!,
      accentContrast: Color.lerp(accentContrast, other.accentContrast, t)!,
      border: Color.lerp(border, other.border, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      focus: Color.lerp(focus, other.focus, t)!,
      modalBackground: Color.lerp(modalBackground, other.modalBackground, t)!,
      modalGradient: _lerpOptionalColors(modalGradient, other.modalGradient, t),
      modalBorder: Color.lerp(modalBorder, other.modalBorder, t)!,
      modalInnerBorder: Color.lerp(
        modalInnerBorder,
        other.modalInnerBorder,
        t,
      )!,
      modalShadow: Color.lerp(modalShadow, other.modalShadow, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
      dangerText: Color.lerp(dangerText, other.dangerText, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      neutralSurface: Color.lerp(neutralSurface, other.neutralSurface, t)!,
    );
  }

  static List<Color> _lerpColors(List<Color> a, List<Color> b, double t) =>
      List<Color>.generate(
        3,
        (index) => Color.lerp(
          a[_sampleIndex(a.length, index)],
          b[_sampleIndex(b.length, index)],
          t,
        )!,
      );

  static List<Color>? _lerpOptionalColors(
    List<Color>? a,
    List<Color>? b,
    double t,
  ) {
    if (a == null || b == null) return t < 0.5 ? a : b;
    return _lerpColors(a, b, t);
  }

  static int _sampleIndex(int length, int index) =>
      length <= 1 ? 0 : (index * (length - 1) / 2).round();
}
