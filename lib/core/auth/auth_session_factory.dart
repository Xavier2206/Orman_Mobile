import 'package:dio/dio.dart';

import '../../app/configuration/app_config.dart';
import '../../features/auth/data/auth_api.dart';
import '../../features/auth/data/auth_service.dart';
import '../../features/auth/data/device_identity.dart';
import '../../features/notifications/data/fcm_fid_registration_bridge.dart';
import '../../features/notifications/data/push_installation_service.dart';
import '../network/api_client.dart';
import '../network/interceptors/auth_interceptor.dart';
import '../network/interceptors/error_interceptor.dart';
import '../network/interceptors/refresh_token_interceptor.dart';
import '../storage/token_storage.dart';
import 'auth_session_events.dart';
import 'session_manager.dart';
import 'token_refresh_coordinator.dart';

/// Aplicación comparte el mismo Dio entre auth y recursos del portal.
class ApplicationDependencies {
  const ApplicationDependencies({
    required this.sessionManager,
    required this.apiClient,
    required this.pushInstallationService,
  });

  final SessionManager sessionManager;
  final ApiClient apiClient;
  final PushInstallationService? pushInstallationService;
}

ApplicationDependencies createApplicationDependencies(
  AppConfig config, {
  InstallationIdSource? installationIds,
  FcmFidRegistrationBridge? fidRegistrationBridge,
}) {
  if ((installationIds == null) != (fidRegistrationBridge == null)) {
    throw ArgumentError(
      'Installation ID changes and FCM FID registration must be configured together.',
    );
  }

  final tokenStorage = SecureTokenStorage();
  final events = AuthSessionEvents();

  BaseOptions options() => BaseOptions(
    baseUrl: config.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 20),
    headers: const {'Accept': 'application/json'},
  );

  final apiDio = Dio(options());
  final apiClient = ApiClient(apiDio);
  final refreshDio = Dio(options());
  final refreshCoordinator = TokenRefreshCoordinator(
    client: refreshDio,
    storage: tokenStorage,
    sessionEvents: events,
  );

  apiDio.interceptors.addAll([
    AuthInterceptor(tokenStorage),
    RefreshTokenInterceptor(
      client: apiDio,
      storage: tokenStorage,
      coordinator: refreshCoordinator,
      sessionEvents: events,
    ),
    ErrorInterceptor(),
  ]);

  final pushInstallationService = installationIds == null
      ? null
      : PushInstallationService(
          apiClient: apiClient,
          installationIds: installationIds,
          registrationBridge: fidRegistrationBridge!,
        );
  pushInstallationService?.start();
  final authService = AuthService(
    authApi: AuthApi(apiClient),
    storage: tokenStorage,
    identity: DeviceIdProvider(),
    device: DeviceNameProvider(),
  );
  return ApplicationDependencies(
    sessionManager: SessionManager(
      service: authService,
      sessionEvents: events,
      lifecycle: pushInstallationService,
    ),
    apiClient: apiClient,
    pushInstallationService: pushInstallationService,
  );
}

/// Compatibilidad para llamadas que solo necesitan autenticación.
SessionManager createAuthSessionManager(AppConfig config) =>
    createApplicationDependencies(config).sessionManager;
