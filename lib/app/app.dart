import 'dart:async';

import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../core/auth/auth_state.dart';
import '../core/auth/session_manager.dart';
import '../features/auth/presentation/authenticated_home_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/notifications/data/notification_navigation_coordinator.dart';
import '../features/notifications/data/notification_refresh_signal.dart';
import '../features/notifications/data/push_installation_service.dart';
import '../features/notifications/data/push_notification_service.dart';
import '../features/payments/presentation/installment_detail_page.dart';
import '../shared/widgets/orman_page_background.dart';
import 'theme/app_theme.dart';
import 'theme/orman_theme_controller.dart';

/// Raíz de ORMAN con tema independiente del brillo del sistema.
class OrmanApp extends StatefulWidget {
  const OrmanApp({
    required this.sessionManager,
    required this.apiClient,
    this.pushInstallationService,
    this.pushNotificationService,
    this.notificationRefreshSignal,
    super.key,
  });

  final SessionManager sessionManager;
  final ApiClient apiClient;
  final PushInstallationService? pushInstallationService;
  final PushNotificationService? pushNotificationService;
  final NotificationRefreshSignal? notificationRefreshSignal;

  @override
  State<OrmanApp> createState() => _OrmanAppState();
}

class _OrmanAppState extends State<OrmanApp> with WidgetsBindingObserver {
  late final OrmanThemeController _themeController;
  late final GlobalKey<NavigatorState> _navigatorKey;
  NotificationNavigationCoordinator? _notificationCoordinator;
  PushNotificationService? _registeredPushService;
  NotificationRefreshSignal? _ownedRefreshSignal;
  NotificationRefreshSignal? _boundRefreshSignal;

  NotificationRefreshSignal get _refreshSignal =>
      widget.notificationRefreshSignal ??
      (_ownedRefreshSignal ??= NotificationRefreshSignal());

  @override
  void initState() {
    super.initState();
    _themeController = OrmanThemeController();
    _navigatorKey = GlobalKey<NavigatorState>();
    WidgetsBinding.instance.addObserver(this);
    _bindNotificationLifecycle();
    unawaited(_themeController.restoreSavedTheme());
    unawaited(widget.sessionManager.restoreSession());
  }

  @override
  void didUpdateWidget(covariant OrmanApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sessionChanged = oldWidget.sessionManager != widget.sessionManager;
    final apiClientChanged = oldWidget.apiClient != widget.apiClient;
    final pushServiceChanged =
        oldWidget.pushNotificationService != widget.pushNotificationService;
    final refreshSignalChanged =
        oldWidget.notificationRefreshSignal != widget.notificationRefreshSignal;
    if (sessionChanged ||
        apiClientChanged ||
        pushServiceChanged ||
        refreshSignalChanged) {
      final oldCoordinator = _notificationCoordinator;
      if (oldCoordinator != null) {
        oldWidget.sessionManager.removeLifecycle(oldCoordinator);
        oldCoordinator.dispose();
      }
      final oldPushService = _registeredPushService;
      if (oldPushService != null) {
        oldWidget.sessionManager.removeLifecycle(oldPushService);
        oldPushService.setDestinationHandler(null);
        oldPushService.setInboxRefreshHandler(null);
        if (oldPushService != widget.pushNotificationService) {
          unawaited(oldPushService.dispose());
        }
      }
      final oldRefreshSignal = _boundRefreshSignal;
      if (oldRefreshSignal != null) {
        oldWidget.sessionManager.removeLifecycle(oldRefreshSignal);
        if (oldWidget.notificationRefreshSignal == null &&
            refreshSignalChanged) {
          oldRefreshSignal.dispose();
          _ownedRefreshSignal = null;
        }
      }
      if (sessionChanged) oldWidget.sessionManager.dispose();
      _bindNotificationLifecycle();
      if (sessionChanged) unawaited(widget.sessionManager.restoreSession());
    }
    if (apiClientChanged) oldWidget.apiClient.close(force: true);
  }

  void _bindNotificationLifecycle() {
    final refreshSignal = _refreshSignal;
    _boundRefreshSignal = refreshSignal;
    widget.sessionManager.addLifecycle(refreshSignal);

    final coordinator = NotificationNavigationCoordinator(
      apiClient: widget.apiClient,
      navigateToInstallment: _navigateToInstallment,
    );
    _notificationCoordinator = coordinator;
    widget.sessionManager.addLifecycle(coordinator);

    final pushService = widget.pushNotificationService;
    _registeredPushService = pushService;
    if (pushService != null) {
      pushService.setDestinationHandler(coordinator.receive);
      pushService.setInboxRefreshHandler(() async {
        refreshSignal.requestRefresh();
      });
      widget.sessionManager.addLifecycle(pushService);
      unawaited(pushService.start());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshSignal.onAppResumed();
  }

  bool _navigateToInstallment(int installmentCode) {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) return false;
    unawaited(
      navigator.push<void>(
        MaterialPageRoute<void>(
          builder: (context) => InstallmentDetailPage(
            apiClient: widget.apiClient,
            installmentCode: installmentCode,
          ),
        ),
      ),
    );
    return true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _themeController.dispose();
    final coordinator = _notificationCoordinator;
    if (coordinator != null) {
      widget.sessionManager.removeLifecycle(coordinator);
      coordinator.dispose();
    }
    final pushService = _registeredPushService;
    if (pushService != null) {
      widget.sessionManager.removeLifecycle(pushService);
      pushService.setDestinationHandler(null);
      pushService.setInboxRefreshHandler(null);
      unawaited(pushService.dispose());
    }
    final refreshSignal = _boundRefreshSignal;
    if (refreshSignal != null) {
      widget.sessionManager.removeLifecycle(refreshSignal);
      if (widget.notificationRefreshSignal == null) refreshSignal.dispose();
    }
    widget.sessionManager.dispose();
    if (widget.pushInstallationService != null) {
      unawaited(widget.pushInstallationService!.dispose());
    }
    widget.apiClient.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return AnimatedBuilder(
          animation: widget.sessionManager,
          builder: (context, _) {
            return MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'ORMAN',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.forKind(_themeController.theme),
              home: switch (widget.sessionManager.state.status) {
                AuthStatus.initializing => const _SessionSplashPage(),
                AuthStatus.unauthenticated => LoginPage(
                  sessionManager: widget.sessionManager,
                  themeController: _themeController,
                  initialMessage: widget.sessionManager.state.message,
                ),
                AuthStatus.authenticated => AuthenticatedHomePage(
                  sessionManager: widget.sessionManager,
                  themeController: _themeController,
                  apiClient: widget.apiClient,
                  contextData: widget.sessionManager.state.context!,
                  notificationRefreshSignal: _refreshSignal,
                ),
              },
            );
          },
        );
      },
    );
  }
}

class _SessionSplashPage extends StatelessWidget {
  const _SessionSplashPage();

  @override
  Widget build(BuildContext context) => OrmanPageBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: const SafeArea(
        child: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      ),
    ),
  );
}
