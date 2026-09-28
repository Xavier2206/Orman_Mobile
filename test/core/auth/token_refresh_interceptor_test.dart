import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/core/network/api_exception.dart';
import 'package:orman/features/auth/data/models/token_pair.dart';

import '../../support/auth_network_stack.dart';
import '../../support/fake_http_adapter.dart';

void main() {
  test(
    'concurrent TOKEN_EXPIRED requests share one rotating refresh',
    () async {
      final storage = MemoryTokenStorage(
        const TokenPair(accessToken: 'access-old', refreshToken: 'refresh-old'),
      );
      var refreshCalls = 0;
      var expiredCalls = 0;
      var retriedCalls = 0;
      String? refreshAuthorization;
      Map<String, dynamic>? refreshBody;

      final stack = createAuthNetworkTestStack(
        storage: storage,
        apiAdapter: CallbackHttpAdapter.withRequestBody((
          options,
          stream,
        ) async {
          if (!options.path.contains('/protected/')) {
            throw StateError('Unexpected protected request ${options.path}');
          }
          final authorization = options.headers['Authorization'];
          if (authorization == 'Bearer access-old') {
            expiredCalls++;
            return jsonResponse(problemJson('TOKEN_EXPIRED'), statusCode: 401);
          }
          if (authorization == 'Bearer access-new') {
            retriedCalls++;
            return jsonResponse({'ok': true});
          }
          throw StateError('Unexpected authorization header: $authorization');
        }),
        refreshAdapter: CallbackHttpAdapter.withRequestBody((
          options,
          stream,
        ) async {
          refreshCalls++;
          refreshAuthorization = options.headers['Authorization'] as String?;
          refreshBody = await _decodeBody(options, stream);
          await Future<void>.delayed(const Duration(milliseconds: 40));
          return jsonResponse(loginResponseJson);
        }),
      );
      addTearDown(stack.close);

      final responses = await Future.wait(
        List.generate(
          5,
          (index) => stack.apiClient.getJson('api/v1/protected/$index'),
        ),
      );

      expect(responses, everyElement({'ok': true}));
      expect(expiredCalls, 5);
      expect(refreshCalls, 1);
      expect(retriedCalls, 5);
      expect(refreshAuthorization, isNull);
      expect(refreshBody, {'refreshToken': 'refresh-old'});
      expect(storage.value?.accessToken, 'access-new');
      expect(storage.value?.refreshToken, 'refresh-new');
    },
  );

  test(
    'invalid refresh clears tokens and emits unauthenticated session event',
    () async {
      final storage = MemoryTokenStorage(
        const TokenPair(accessToken: 'access-old', refreshToken: 'refresh-old'),
      );
      var refreshCalls = 0;
      final stack = createAuthNetworkTestStack(
        storage: storage,
        apiAdapter: CallbackHttpAdapter(
          (options) async =>
              jsonResponse(problemJson('TOKEN_EXPIRED'), statusCode: 401),
        ),
        refreshAdapter: CallbackHttpAdapter((options) async {
          refreshCalls++;
          return jsonResponse(
            problemJson('INVALID_REFRESH_TOKEN'),
            statusCode: 401,
          );
        }),
      );
      addTearDown(stack.close);

      await expectLater(
        stack.apiClient.getJson('api/v1/protected/profile'),
        throwsA(isA<ApiException>()),
      );

      expect(refreshCalls, 1);
      expect(storage.value, isNull);
      expect(stack.events.message, contains('Tu sesión ya no está activa'));
    },
  );

  test(
    'a retried TOKEN_EXPIRED response never starts another refresh',
    () async {
      final storage = MemoryTokenStorage(
        const TokenPair(accessToken: 'access-old', refreshToken: 'refresh-old'),
      );
      var protectedCalls = 0;
      var refreshCalls = 0;
      final stack = createAuthNetworkTestStack(
        storage: storage,
        apiAdapter: CallbackHttpAdapter((options) async {
          protectedCalls++;
          return jsonResponse(problemJson('TOKEN_EXPIRED'), statusCode: 401);
        }),
        refreshAdapter: CallbackHttpAdapter((options) async {
          refreshCalls++;
          return jsonResponse(loginResponseJson);
        }),
      );
      addTearDown(stack.close);

      await expectLater(
        stack.apiClient.getJson('api/v1/protected/profile'),
        throwsA(isA<ApiException>()),
      );

      expect(protectedCalls, 2);
      expect(refreshCalls, 1);
      expect(storage.value, isNull);
    },
  );

  test('SESSION_REVOKED clears storage without requesting a refresh', () async {
    final storage = MemoryTokenStorage(
      const TokenPair(accessToken: 'access-old', refreshToken: 'refresh-old'),
    );
    var refreshCalls = 0;
    final stack = createAuthNetworkTestStack(
      storage: storage,
      apiAdapter: CallbackHttpAdapter(
        (options) async =>
            jsonResponse(problemJson('SESSION_REVOKED'), statusCode: 401),
      ),
      refreshAdapter: CallbackHttpAdapter((options) async {
        refreshCalls++;
        throw StateError('A revoked session must not refresh.');
      }),
    );
    addTearDown(stack.close);

    await expectLater(
      stack.apiClient.getJson('api/v1/protected/profile'),
      throwsA(isA<ApiException>()),
    );

    expect(refreshCalls, 0);
    expect(storage.value, isNull);
  });
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
