import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_shell.dart';
import 'providers/documents_provider.dart';
import 'services/document_repository.dart';

class DocConvertApp extends StatelessWidget {
  const DocConvertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DocumentsProvider(DocumentRepository())..load(),
      child: MaterialApp(
        title: 'DocConvert NCTS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const HomeShell(),
      ),
    );
  }
}
