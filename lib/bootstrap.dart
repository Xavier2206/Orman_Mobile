import 'package:flutter/material.dart';
import 'app/app.dart';

/// Inicialización y arranque global de la aplicación ORMAN.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const OrmanApp());
}
