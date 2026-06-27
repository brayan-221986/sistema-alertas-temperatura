import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SistemaAlertasApp());
}

class SistemaAlertasApp extends StatelessWidget {
  const SistemaAlertasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Alertas',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
