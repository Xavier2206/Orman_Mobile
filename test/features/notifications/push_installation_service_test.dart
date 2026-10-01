import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orman/core/auth/session_manager.dart';
import 'package:orman/core/network/api_endpoints.dart';
import 'package:orman/features/notifications/data/fcm_fid_registration_bridge.dart';
import 'package:orman/features/notifications/data/push_installation_service.dart';
import 'package:orman/features/auth/data/models/token_pair.dart';

import '../../support/auth_network_stack.dart';
import '../../support/fake_auth_session_service.dart';
import '../../support/fake_http_adapter.dart';

void main() {
  final initialFid = _validFid('c', 'a');
  final changedFid = _validFid('d', 'b');
  final confirmedChangedFid = _validFid('e', 'c');
  late PushFixture fixture;

  setUp(() => fixture = PushFixture());
  tearDown(() => fixture.dispose());

  test(
    'does not register an installation without an authenticated session',
    () async {
      await fixture.manager.restoreSession();
      fixture.installations.rotate(changedFid);
      await _settleAsyncWork();

      expect(fixture.requests, isEmpty);
      expect(fixture.registration.calls, 0);
    },
  );

  test(
    'registers the FID after a successful login with only contract fields',
    () async {
      await fixture.manager.signIn(login: 'inquilino.demo', password: 'secret');
      await _settleAsyncWork();

      expect(fixture.manager.state.status.name, 'authenticated');
      expect(fixture.requests, hasLength(1));
      expect(
        fixture.requests.single.path,
        endsWith(ApiEndpoints.pushInstallation),
      );
      expect(fixture.requests.single.authorization, 'Bearer access-test');
      expect(fixture.requests.single.body, {
        'installationId': initialFid,
        'platform': 'ANDROID',
      });
      expect(fixture.registration.calls, 1);
    },
  );

  test('registers the FID after restoring an authenticated session', () async {
    fixture.auth.onRestore = () async => testAuthContext;

    await fixture.manager.restoreSession();
    await _settleAsyncWork();

    expect(fixture.requests, hasLength(1));
    expect(fixture.registration.calls, 1);
  });

  test('accepts the Backend 204 response as a completed sync', () async {
    await fixture.manager.signIn(login: 'inquilino.demo', password: 'secret');
    await _settleAsyncWork();

    expect(fixture.requests.single.statusCode, 204);
    expect(fixture.manager.state.status.name, 'authenticated');
  });

  test('a Firebase FID error does not break login', () async {
    fixture.registration.error = StateError('private Firebase detail');

    await fixture.manager.signIn(login: 'inquilino.demo', password: 'secret');
    await _settleAsyncWork();

    expect(fixture.manager.state.status.name, 'authenticated');
    expect(fixture.requests, isEmpty);
  });

  test(
    'an invalid FID returned by the bridge is not sent to Backend',
    () async {
      fixture.registration.currentFid = 'not-a-fid';

      await fixture.manager.signIn(login: 'inquilino.demo', password: 'secret');
      await _settleAsyncWork();

      expect(fixture.manager.state.status.name, 'authenticated');
      expect(fixture.registration.calls, 1);
      expect(fixture.requests, isEmpty);
    },
  );

  test('a Backend error does not break login', () async {
    fixture.backendStatusCode = 503;

    await fixture.manager.signIn(login: 'inquilino.demo', password: 'secret');
    await _settleAsyncWork();

    expect(fixture.manager.state.status.name, 'authenticated');
    expect(fixture.requests, hasLength(1));
  });

  test('synchronizes a changed FID while authenticated', () async {
    await fixture.manager.signIn(login: 'inquilino.demo', password: 'secret');
    await _settleAsyncWork();
    fixture.registration.currentFid = confirmedChangedFid;
    fixture.installations.rotate(changedFid);
    await _settleAsyncWork();

    expect(fixture.requests, hasLength(2));
    expect(fixture.requests.last.body['installationId'], confirmedChangedFid);
    expect(fixture.registration.calls, 2);
  });

  test(
    'does not send an authenticated request for an unauthenticated FID change',
    () async {
      await fixture.manager.restoreSession();
      fixture.installations.rotate(changedFid);
      await _settleAsyncWork();

      expect(fixture.requests, isEmpty);
    },
  );

  test('does not register again after logout', () async {
    await fixture.manager.signIn(login: 'inquilino.demo', password: 'secret');
    await _settleAsyncWork();
    await fixture.manager.signOut();
    fixture.installations.rotate(changedFid);
    await _settleAsyncWork();

    expect(fixture.requests, hasLength(1));
    expect(fixture.registration.calls, 1);
    expect(fixture.manager.state.status.name, 'unauthenticated');
  });

  test('registers the same FID again after the next user logs in', () async {
    await fixture.manager.signIn(login: 'inquilino.a', password: 'secret');
    await _settleAsyncWork();
    await fixture.manager.signOut();
    await fixture.manager.signIn(login: 'inquilino.b', password: 'secret');
    await _settleAsyncWork();

    expect(fixture.requests, hasLength(2));
    expect(fixture.registration.calls, 2);
    expect(
      fixture.requests.map((request) => request.body['installationId']),
      everyElement(initialFid),
    );
  });
}

Future<void> _settleAsyncWork() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

class PushFixture {
  PushFixture() {
    final adapter = CallbackHttpAdapter.withRequestBody((
      options,
      stream,
    ) async {
      if (!options.path.endsWith(ApiEndpoints.pushInstallation)) {
        throw StateError('Unexpected request path.');
      }
      requests.add(
        RecordedPushRequest(
          path: options.path,
          authorization: options.headers['Authorization'] as String?,
          body: await _decodeRequestBody(options, stream),
          statusCode: backendStatusCode,
        ),
      );
      return emptyResponse(statusCode: backendStatusCode);
    });
    stack = createAuthNetworkTestStack(
      storage: MemoryTokenStorage(
        const TokenPair(
          accessToken: 'access-test',
          refreshToken: 'refresh-test',
        ),
      ),
      apiAdapter: adapter,
      refreshAdapter: CallbackHttpAdapter((options) async {
        throw StateError('Unexpected refresh request.');
      }),
    );
    pushService = PushInstallationService(
      apiClient: stack.apiClient,
      installationIds: installations,
      registrationBridge: registration,
    )..start();
    manager = SessionManager(
      service: auth,
      sessionEvents: stack.events,
      lifecycle: pushService,
    );
  }

  final installations = FakeInstallationIdSource();
  final registration = FakeFcmFidRegistrationBridge();
  final auth = FakeAuthSessionService();
  final requests = <RecordedPushRequest>[];
  late AuthNetworkTestStack stack;
  late PushInstallationService pushService;
  late SessionManager manager;
  int backendStatusCode = 204;

  Future<void> dispose() async {
    manager.dispose();
    await pushService.dispose();
    await installations.close();
    stack.close();
  }
}

class FakeInstallationIdSource implements InstallationIdSource {
  final StreamController<String> _changes = StreamController<String>.broadcast(
    sync: true,
  );

  @override
  Stream<String> get onIdChange => _changes.stream;

  void rotate(String installationId) {
    _changes.add(installationId);
  }

  Future<void> close() => _changes.close();
}

class FakeFcmFidRegistrationBridge implements FcmFidRegistrationBridge {
  String currentFid = _validFid('c', 'a');
  Object? error;
  int calls = 0;

  @override
  Future<String> registerFid() async {
    calls++;
    if (error case final registrationError?) throw registrationError;
    return currentFid;
  }
}

String _validFid(String prefix, String character) =>
    '$prefix${List<String>.filled(21, character).join()}';

class RecordedPushRequest {
  const RecordedPushRequest({
    required this.path,
    required this.authorization,
    required this.body,
    required this.statusCode,
  });

  final String path;
  final String? authorization;
  final Map<String, dynamic> body;
  final int statusCode;
}

Future<Map<String, dynamic>> _decodeRequestBody(
  RequestOptions options,
  Stream<Uint8List>? stream,
) async {
  final data = options.data;
  if (data is Map) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
  if (stream == null) throw StateError('Expected a JSON request body.');
  final decoded = jsonDecode(await utf8.decoder.bind(stream).join());
  if (decoded is Map) {
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }
  throw StateError('Expected an object request body.');
}
