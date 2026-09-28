import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orman/app/configuration/app_config.dart';
import 'package:orman/core/network/problem_detail.dart';
import 'package:orman/core/storage/storage_keys.dart';
import 'package:orman/core/storage/token_storage.dart';
import 'package:orman/features/auth/data/device_identity.dart';
import 'package:orman/features/auth/data/models/auth_context.dart';
import 'package:orman/features/auth/data/models/login_request.dart';
import 'package:orman/features/auth/data/models/login_response.dart';
import 'package:orman/features/auth/data/models/token_pair.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  test(
    'LoginRequest has the exact MOBILE JSON contract and redacts password',
    () {
      const request = LoginRequest(
        login: 'inquilino.demo',
        password: 'secret-password',
        deviceId: 'device-uuid',
        deviceName: 'Samsung SM-A556E',
      );

      expect(request.toJson(), {
        'login': 'inquilino.demo',
        'password': 'secret-password',
        'deviceId': 'device-uuid',
        'deviceName': 'Samsung SM-A556E',
        'clientType': 'MOBILE',
      });
      expect(request.toString(), isNot(contains('secret-password')));
    },
  );

  test('LoginResponse handles an omitted challengeId and parses tokens', () {
    final response = LoginResponse.fromJson(loginResponseJson);

    expect(response.status, 'AUTHENTICATED');
    expect(response.challengeId, isNull);
    expect(response.login, 'inquilino.demo');
    expect(response.codper, 123);
    expect(response.tokenPair.accessToken, 'access-new');
    expect(response.tokenPair.refreshToken, 'refresh-new');
    expect(response.sid, '11111111-2222-3333-4444-555555555555');
    expect(response.toString(), isNot(contains('access-new')));
  });

  test('ProblemDetail parses validation field errors', () {
    final detail = ProblemDetail.fromJson({
      ...problemJson(
        'VALIDATION_ERROR',
        status: 400,
        detail: 'Uno o más campos no son válidos.',
      ),
      'fieldErrors': [
        {'field': 'login', 'message': 'El login es obligatorio.'},
      ],
    });

    expect(detail.errorCode, 'VALIDATION_ERROR');
    expect(detail.status, 400);
    expect(detail.fieldErrors.single.field, 'login');
    expect(detail.fieldErrors.single.message, 'El login es obligatorio.');
    expect(detail.timestamp, isNotNull);
  });

  test(
    'AuthContext parses nested usuario, persona, roles, menus and procesos',
    () {
      final context = AuthContext.fromJson(authContextJson);

      expect(context.usuario.login, 'inquilino.demo');
      expect(context.nombreCompleto, 'Juan Pérez López');
      expect(context.rolesLabel, 'INQUILINO');
      expect(context.roles.single.menus.single.nombre, 'Portal');
      expect(
        context.roles.single.menus.single.procesos.single.enlace,
        'portal/inicio',
      );
    },
  );

  test(
    'secure token storage saves the rotating pair in one secure value',
    () async {
      final keyValueStore = MemorySecureKeyValueStore();
      final storage = SecureTokenStorage(storage: keyValueStore);
      const tokens = TokenPair(
        accessToken: 'access-secret',
        refreshToken: 'refresh-secret',
      );

      await storage.saveTokens(tokens);
      expect(keyValueStore.values.keys, [StorageKeys.authTokenPair]);
      final stored = jsonDecode(
        keyValueStore.values[StorageKeys.authTokenPair]!,
      );
      expect(stored['accessToken'], 'access-secret');
      expect(stored['refreshToken'], 'refresh-secret');
      expect(await storage.readAccessToken(), 'access-secret');
      expect(await storage.readRefreshToken(), 'refresh-secret');

      await storage.clear();
      expect(await storage.readTokens(), isNull);
    },
  );

  test(
    'device id is a persisted UUID stable across provider instances',
    () async {
      SharedPreferences.setMockInitialValues({});
      final first = await DeviceIdProvider().getStableId();
      final second = await DeviceIdProvider().getStableId();

      expect(first, second);
      expect(
        RegExp(
          r'^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$',
        ).hasMatch(first),
        isTrue,
      );
    },
  );

  test(
    'AppConfig uses local emulator in debug and requires HTTPS in release',
    () {
      expect(
        AppConfig.fromEnvironment(value: '', releaseMode: false).apiBaseUrl,
        'http://10.0.2.2:9090/',
      );
      expect(
        AppConfig.fromEnvironment(
          value: 'https://api.example.test',
          releaseMode: true,
        ).apiBaseUrl,
        'https://api.example.test/',
      );
      expect(
        () => AppConfig.fromEnvironment(value: '', releaseMode: true),
        throwsStateError,
      );
      expect(
        () => AppConfig.fromEnvironment(
          value: 'http://10.0.2.2:9090',
          releaseMode: true,
        ),
        throwsStateError,
      );
    },
  );
}
