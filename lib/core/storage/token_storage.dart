import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/data/models/token_pair.dart';
import 'storage_keys.dart';

abstract interface class SecureKeyValueStore {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class FlutterSecureKeyValueStore implements SecureKeyValueStore {
  FlutterSecureKeyValueStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

/// Único punto de acceso de la app a los tokens de sesión.
abstract interface class TokenStorage {
  Future<void> saveTokens(TokenPair tokens);
  Future<TokenPair?> readTokens();
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> clear();
}

/// Guarda la pareja rotativa en una sola entrada cifrada del sistema.
class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage({SecureKeyValueStore? storage})
    : _storage = storage ?? FlutterSecureKeyValueStore();

  final SecureKeyValueStore _storage;

  @override
  Future<void> saveTokens(TokenPair tokens) async {
    await _storage.write(
      key: StorageKeys.authTokenPair,
      value: jsonEncode(tokens.toJson()),
    );
  }

  @override
  Future<TokenPair?> readTokens() async {
    final encoded = await _storage.read(key: StorageKeys.authTokenPair);
    if (encoded == null || encoded.isEmpty) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is Map) {
        return TokenPair.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } on FormatException {
      // Una entrada corrupta nunca se trata como sesión válida.
    }
    await clear();
    return null;
  }

  @override
  Future<String?> readAccessToken() async => (await readTokens())?.accessToken;

  @override
  Future<String?> readRefreshToken() async =>
      (await readTokens())?.refreshToken;

  @override
  Future<void> clear() => _storage.delete(key: StorageKeys.authTokenPair);
}
