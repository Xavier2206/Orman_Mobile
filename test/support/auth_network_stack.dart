import 'package:dio/dio.dart';
import 'package:orman/core/auth/auth_session_events.dart';
import 'package:orman/core/auth/token_refresh_coordinator.dart';
import 'package:orman/core/network/api_client.dart';
import 'package:orman/core/network/interceptors/auth_interceptor.dart';
import 'package:orman/core/network/interceptors/error_interceptor.dart';
import 'package:orman/core/network/interceptors/refresh_token_interceptor.dart';
import 'package:orman/core/storage/token_storage.dart';

import 'fake_http_adapter.dart';

class AuthNetworkTestStack {
  AuthNetworkTestStack({
    required this.apiDio,
    required this.refreshDio,
    required this.apiClient,
    required this.events,
  });

  final Dio apiDio;
  final Dio refreshDio;
  final ApiClient apiClient;
  final AuthSessionEvents events;

  void close() {
    apiDio.close(force: true);
    refreshDio.close(force: true);
    events.dispose();
  }
}

AuthNetworkTestStack createAuthNetworkTestStack({
  required TokenStorage storage,
  required CallbackHttpAdapter apiAdapter,
  required CallbackHttpAdapter refreshAdapter,
}) {
  Dio createDio(CallbackHttpAdapter adapter) {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.example.test/',
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
      ),
    );
    dio.httpClientAdapter = adapter;
    return dio;
  }

  final apiDio = createDio(apiAdapter);
  final refreshDio = createDio(refreshAdapter);
  final events = AuthSessionEvents();
  final coordinator = TokenRefreshCoordinator(
    client: refreshDio,
    storage: storage,
    sessionEvents: events,
  );
  apiDio.interceptors.addAll([
    AuthInterceptor(storage),
    RefreshTokenInterceptor(
      client: apiDio,
      storage: storage,
      coordinator: coordinator,
      sessionEvents: events,
    ),
    ErrorInterceptor(),
  ]);

  return AuthNetworkTestStack(
    apiDio: apiDio,
    refreshDio: refreshDio,
    apiClient: ApiClient(apiDio),
    events: events,
  );
}
