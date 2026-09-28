import 'package:flutter/foundation.dart';

const _apiBaseUrlDefine = String.fromEnvironment('API_BASE_URL');

/// Configuración central de red de la aplicación ORMAN.
class AppConfig {
  const AppConfig._({required this.apiBaseUrl, required this.apiBaseUri});

  /// Base URL normalizada con `/` al final para resolver endpoints relativos.
  final String apiBaseUrl;
  final Uri apiBaseUri;

  /// En debug se permite el emulador Android local como valor predeterminado.
  /// En release se exige una URL explícita por `--dart-define` y HTTPS.
  factory AppConfig.fromEnvironment({String? value, bool? releaseMode}) {
    final isRelease = releaseMode ?? kReleaseMode;
    var candidate = (value ?? _apiBaseUrlDefine).trim();

    if (candidate.isEmpty) {
      if (isRelease) {
        throw StateError(
          'API_BASE_URL es obligatoria en builds release y debe usar HTTPS.',
        );
      }
      candidate = 'http://10.0.2.2:9090';
    }

    final uri = Uri.tryParse(candidate);
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.scheme != 'https' && uri.scheme != 'http')) {
      throw StateError('API_BASE_URL no es una URL HTTP(S) absoluta válida.');
    }

    if (isRelease && uri.scheme != 'https') {
      throw StateError('API_BASE_URL debe usar HTTPS en builds release.');
    }

    final normalized = uri.replace(
      path: '${uri.path.replaceFirst(RegExp(r'/+$'), '')}/',
    );
    return AppConfig._(
      apiBaseUrl: normalized.toString(),
      apiBaseUri: normalized,
    );
  }
}
