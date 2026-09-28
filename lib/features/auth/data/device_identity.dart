import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/storage/storage_keys.dart';

/// Genera y persiste una sola identidad UUID por instalación.
class DeviceIdProvider {
  DeviceIdProvider({
    Future<SharedPreferences> Function()? preferencesLoader,
    Uuid? uuid,
  }) : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
       _uuid = uuid ?? const Uuid();

  final Future<SharedPreferences> Function() _preferencesLoader;
  final Uuid _uuid;
  Future<String>? _pending;

  Future<String> getStableId() {
    final pending = _pending;
    if (pending != null) return pending;
    final creation = _loadOrCreate();
    _pending = creation;
    return creation;
  }

  Future<String> _loadOrCreate() async {
    try {
      final preferences = await _preferencesLoader();
      final current = preferences.getString(StorageKeys.deviceId);
      if (current != null && current.trim().isNotEmpty) return current;

      final created = _uuid.v4();
      final saved = await preferences.setString(StorageKeys.deviceId, created);
      if (!saved) {
        throw StateError(
          'No se pudo guardar el identificador del dispositivo.',
        );
      }
      return created;
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }
}

/// Nombre seguro y acotado para asociar la sesión con el dispositivo.
class DeviceNameProvider {
  DeviceNameProvider({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  Future<String> getDeviceName() async {
    if (kIsWeb) return 'Android';

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _plugin.androidInfo;
        final manufacturer = _capitalize(info.manufacturer.trim());
        final model = info.model.trim();
        final name = manufacturer.isEmpty
            ? model
            : model.isEmpty || manufacturer.toLowerCase() == model.toLowerCase()
            ? manufacturer
            : '$manufacturer $model';
        return _limit(name.isEmpty ? 'Android' : name);
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final modelName = (await _plugin.iosInfo).modelName.trim();
        return _limit(modelName.isEmpty ? 'iPhone' : modelName);
      }
      return 'Android';
    } on Object {
      return defaultTargetPlatform == TargetPlatform.iOS ? 'iPhone' : 'Android';
    }
  }

  String _capitalize(String value) =>
      value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';

  String _limit(String value) =>
      value.length <= 100 ? value : value.substring(0, 100);
}
