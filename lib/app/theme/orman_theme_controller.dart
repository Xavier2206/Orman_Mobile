import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'orman_theme_kind.dart';

/// Mantiene la elección del tema en memoria y en preferencias de usuario.
class OrmanThemeController extends ChangeNotifier {
  OrmanThemeController({OrmanThemeKind initialTheme = OrmanThemeKind.orman})
    : _theme = initialTheme;

  static const String storageKey = 'orman-theme';

  OrmanThemeKind _theme;
  int _revision = 0;
  bool _disposed = false;
  Future<void> _writeQueue = Future<void>.value();

  OrmanThemeKind get theme => _theme;

  /// Carga la preferencia sin retrasar el primer render ORMAN.
  Future<void> restoreSavedTheme() async {
    final revisionAtStart = _revision;
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_disposed || revisionAtStart != _revision) return;

      final savedTheme = OrmanThemeKind.fromStorageValue(
        preferences.getString(storageKey),
      );
      if (savedTheme == null || savedTheme == _theme) return;

      _theme = savedTheme;
      _revision++;
      notifyListeners();
    } on Object {
      // La selección en memoria sigue disponible si el almacenamiento falla.
    }
  }

  /// Actualiza la UI inmediatamente y encola la persistencia para conservar
  /// el orden si el usuario cambia de tema varias veces seguidas.
  Future<void> setTheme(OrmanThemeKind theme) {
    if (_disposed || theme == _theme) return Future<void>.value();

    _theme = theme;
    _revision++;
    notifyListeners();

    _writeQueue = _writeQueue.then((_) async {
      if (_disposed) return;
      try {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setString(storageKey, theme.storageValue);
      } on Object {
        // No se revierte el cambio visual por un fallo de preferencias.
      }
    });
    return _writeQueue;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
