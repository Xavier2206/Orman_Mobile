import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/core/network/api_exception.dart';
import 'package:orman/features/auth/data/auth_api.dart';
import 'package:orman/features/auth/data/auth_service.dart';
import 'package:orman/features/auth/data/device_identity.dart';
import 'package:orman/features/auth/data/models/token_pair.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_network_stack.dart';
import '../../support/fake_http_adapter.dart';

void main() {
  test(
    'login saves tokens, requests auth/context and sends MOBILE metadata',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = MemoryTokenStorage();
      Map<String, dynamic>? loginBody;
      String? contextAuthorization;
      var refreshCalls = 0;

      final stack = createAuthNetworkTestStack(
        storage: storage,
        apiAdapter: CallbackHttpAdapter.withRequestBody((
          options,
          stream,
        ) async {
          if (options.path.endsWith('/auth/login')) {
            loginBody = await _decodeBody(options, stream);
            expect(options.headers.containsKey('Authorization'), isFalse);
            return jsonResponse(loginResponseJson);
          }
          if (options.path.endsWith('/auth/context')) {
            contextAuthorization = options.headers['Authorization'] as String?;
            return jsonResponse(authContextJson);
          }
          if (options.path.endsWith('/auth/logout')) return emptyResponse();
          throw StateError('Unexpected request ${options.path}');
        }),
        refreshAdapter: CallbackHttpAdapter((options) async {
          refreshCalls++;
          throw StateError('Login must not refresh: ${options.path}');
        }),
      );
      addTearDown(stack.close);
      final service = AuthService(
        authApi: AuthApi(stack.apiClient),
        storage: storage,
        identity: DeviceIdProvider(),
        device: DeviceNameProvider(),
      );

      final context = await service.signIn(
        login: '  inquilino.demo  ',
        password: '  clave-ficticia  ',
      );

      expect(loginBody, isNotNull);
      expect(loginBody!['login'], 'inquilino.demo');
      expect(loginBody!['password'], '  clave-ficticia  ');
      expect(loginBody!['clientType'], 'MOBILE');
      expect(loginBody!['deviceId'], isA<String>());
      expect(loginBody!['deviceName'], isA<String>());
      expect(
        (loginBody!['deviceName'] as String).length,
        lessThanOrEqualTo(100),
      );
      expect(contextAuthorization, 'Bearer access-new');
      expect(context.nombreCompleto, 'Juan Pérez López');
      expect(storage.value?.accessToken, 'access-new');
      expect(storage.value?.refreshToken, 'refresh-new');
      expect(refreshCalls, 0);

      await service.signOut();
      expect(storage.value, isNull);
    },
  );

  test(
    'INVALID_CREDENTIALS is shown without storing tokens or refreshing',
    () async {
      final storage = MemoryTokenStorage();
      var refreshCalls = 0;
      final stack = createAuthNetworkTestStack(
        storage: storage,
        apiAdapter: CallbackHttpAdapter((options) async {
          expect(options.path, endsWith('/auth/login'));
          return jsonResponse(
            problemJson(
              'INVALID_CREDENTIALS',
              title: 'Credenciales inválidas',
              detail: 'Las credenciales no son válidas.',
            ),
            statusCode: 401,
          );
        }),
        refreshAdapter: CallbackHttpAdapter((options) async {
          refreshCalls++;
          throw StateError('Invalid credentials must not refresh.');
        }),
      );
      addTearDown(stack.close);
      final service = AuthService(
        authApi: AuthApi(stack.apiClient),
        storage: storage,
        identity: DeviceIdProvider(),
        device: DeviceNameProvider(),
      );

      await expectLater(
        service.signIn(login: 'inquilino.demo', password: 'secreto-validado'),
        throwsA(
          isA<ApiException>()
              .having(
                (error) => error.errorCode,
                'errorCode',
                'INVALID_CREDENTIALS',
              )
              .having(
                (error) => error.detail,
                'detail',
                'Las credenciales no son válidas.',
              ),
        ),
      );
      expect(storage.value, isNull);
      expect(refreshCalls, 0);
    },
  );

  test(
    'logout clears local tokens even if the backend is unreachable',
    () async {
      final storage = MemoryTokenStorage(
        const TokenPair(accessToken: 'access-old', refreshToken: 'refresh-old'),
      );
      final stack = createAuthNetworkTestStack(
        storage: storage,
        apiAdapter: CallbackHttpAdapter((options) async {
          throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          );
        }),
        refreshAdapter: CallbackHttpAdapter((options) async {
          throw StateError('No refresh is expected.');
        }),
      );
      addTearDown(stack.close);
      final service = AuthService(
        authApi: AuthApi(stack.apiClient),
        storage: storage,
        identity: DeviceIdProvider(),
        device: DeviceNameProvider(),
      );

      await service.signOut();

      expect(storage.value, isNull);
      expect(storage.clearCount, 1);
    },
  );
}

Future<Map<String, dynamic>> _decodeBody(
  RequestOptions options,
  Stream<Uint8List>? stream,
) async {
  if (options.data is Map) {
    return (options.data as Map).map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }
  if (stream != null) {
    final body = await utf8.decoder.bind(stream).join();
    final decoded = jsonDecode(body);
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  }
  throw StateError('Expected a JSON request body.');
}
