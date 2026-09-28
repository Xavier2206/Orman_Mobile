import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:orman/core/storage/token_storage.dart';
import 'package:orman/features/auth/data/models/token_pair.dart';

class CallbackHttpAdapter implements HttpClientAdapter {
  factory CallbackHttpAdapter(
    Future<ResponseBody> Function(RequestOptions options) onRequest,
  ) => CallbackHttpAdapter.withRequestBody(
    (options, requestStream) => onRequest(options),
  );

  CallbackHttpAdapter.withRequestBody(this._onRequest);

  final Future<ResponseBody> Function(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
  )
  _onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _onRequest(options, requestStream);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonResponse(Object? body, {int statusCode = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody emptyResponse({int statusCode = 204}) => ResponseBody.fromString(
  '',
  statusCode,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

Map<String, Object> problemJson(
  String errorCode, {
  int status = 401,
  String title = 'Sesión no válida',
  String detail = 'La sesión ya no es válida.',
}) => {
  'type': 'about:blank',
  'title': title,
  'status': status,
  'detail': detail,
  'instance': '/api/v1/auth/context',
  'errorCode': errorCode,
  'timestamp': '2026-09-27T12:00:00Z',
  'traceId': 'test-trace',
};

class MemoryTokenStorage implements TokenStorage {
  TokenPair? value;
  int saveCount = 0;
  int clearCount = 0;

  MemoryTokenStorage([this.value]);

  @override
  Future<void> saveTokens(TokenPair tokens) async {
    value = tokens;
    saveCount++;
  }

  @override
  Future<TokenPair?> readTokens() async => value;

  @override
  Future<String?> readAccessToken() async => value?.accessToken;

  @override
  Future<String?> readRefreshToken() async => value?.refreshToken;

  @override
  Future<void> clear() async {
    value = null;
    clearCount++;
  }
}

class MemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> delete({required String key}) async {
    values.remove(key);
  }
}

const loginResponseJson = <String, Object>{
  'status': 'AUTHENTICATED',
  'login': 'inquilino.demo',
  'codper': 123,
  'accessToken': 'access-new',
  'refreshToken': 'refresh-new',
  'tokenType': 'Bearer',
  'expiresIn': 900,
  'sid': '11111111-2222-3333-4444-555555555555',
};

const authContextJson = <String, Object>{
  'usuario': {'login': 'inquilino.demo', 'codper': 123},
  'persona': {
    'nombre': 'Juan',
    'ap': 'Pérez',
    'am': 'López',
    'foto': 'https://example.test/persona.png',
  },
  'roles': [
    {
      'codr': 8,
      'nombre': 'INQUILINO',
      'menus': [
        {
          'codm': 3,
          'nombre': 'Portal',
          'icono': 'home',
          'procesos': [
            {'codp': 12, 'nombre': 'Inicio', 'enlace': 'portal/inicio'},
          ],
        },
      ],
    },
  ],
};
