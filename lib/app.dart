import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';

class DocConvertApp extends StatelessWidget {
  const DocConvertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocConvert NCTS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      // "Modo del sistema" por defecto, como pide la especificación;
      // el usuario podrá forzar claro/oscuro más adelante (Fase 7,
      // Ajustes) sin que esto tenga que cambiar de estructura.
      themeMode: ThemeMode.system,
      home: const HomeShell(),
    );
  }
}
