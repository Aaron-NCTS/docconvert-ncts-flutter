import 'package:flutter/material.dart';

import '../documents/documents_screen.dart';
import '../scanner/scanner_screen.dart';
import '../tools/tools_screen.dart';
import 'home_screen.dart';

/// Contenedor principal de navegación.
///
/// Cambio de diseño respecto a la versión anterior (feedback: el botón de
/// Escanear se sentía "exageradamente más grande" y desequilibraba la
/// barra): ahora las 4 secciones (Inicio, Escanear, Documentos,
/// Herramientas) son destinos normales de una NavigationBar estándar de
/// Material 3, todas del mismo tamaño. "Escanear" sigue siendo la función
/// principal, pero se destaca con color e ícono relleno cuando está
/// seleccionada -- no con un tamaño distinto a los demás.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  void _goToTab(int index) => setState(() => _tabIndex = index);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeScreen(onNavigateToTab: _goToTab),
      const ScannerScreen(),
      const DocumentsScreen(),
      const ToolsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: _goToTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Escanear',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Documentos',
          ),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Herramientas',
          ),
        ],
      ),
    );
  }
}
