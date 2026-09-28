/// Temas disponibles en la aplicación.
enum OrmanThemeKind {
  orman('orman', 'ORMAN'),
  light('light', 'Día'),
  dark('dark', 'Noche');

  const OrmanThemeKind(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static OrmanThemeKind? fromStorageValue(String? value) {
    for (final kind in values) {
      if (kind.storageValue == value) return kind;
    }
    return null;
  }
}
