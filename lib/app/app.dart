import 'dart:async';

import 'package:flutter/material.dart';

import '../core/network/api_client.dart';
import '../core/auth/auth_state.dart';
import '../core/auth/session_manager.dart';
import '../features/auth/presentation/authenticated_home_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../shared/widgets/orman_page_background.dart';
import 'theme/app_theme.dart';
import 'theme/orman_theme_controller.dart';

/// Raíz de ORMAN con tema independiente del brillo del sistema.
class OrmanApp extends StatefulWidget {
  const OrmanApp({
    required this.sessionManager,
    required this.apiClient,
    super.key,
  });

  final SessionManager sessionManager;
  final ApiClient apiClient;

  @override
  State<OrmanApp> createState() => _OrmanAppState();
}

class _OrmanAppState extends State<OrmanApp> {
  late final OrmanThemeController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = OrmanThemeController();
    unawaited(_themeController.restoreSavedTheme());
    unawaited(widget.sessionManager.restoreSession());
  }

  @override
  void didUpdateWidget(covariant OrmanApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sessionManager != widget.sessionManager) {
      oldWidget.sessionManager.dispose();
      unawaited(widget.sessionManager.restoreSession());
    }
    if (oldWidget.apiClient != widget.apiClient) {
      oldWidget.apiClient.close(force: true);
    }
  }

  @override
  void dispose() {
    _themeController.dispose();
    widget.sessionManager.dispose();
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
