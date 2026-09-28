import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/configuration/app_config.dart';
import 'core/auth/auth_session_factory.dart';

/// Inicialización y arranque global de la aplicación ORMAN.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final dependencies = createApplicationDependencies(config);
  runApp(
    OrmanApp(
      sessionManager: dependencies.sessionManager,
      apiClient: dependencies.apiClient,
    ),
  );
}
