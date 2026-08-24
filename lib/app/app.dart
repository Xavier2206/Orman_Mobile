import 'package:flutter/material.dart';

/// Componente raíz de la aplicación ORMAN.
class OrmanApp extends StatelessWidget {
  const OrmanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'ORMAN',
      home: Scaffold(
        body: Center(
          child: Text('ORMAN Base App'),
        ),
      ),
    );
  }
}
