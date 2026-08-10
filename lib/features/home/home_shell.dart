import 'package:flutter/material.dart';

import '../documents/documents_screen.dart';
import '../scanner/scanner_screen.dart';
import '../tools/tools_screen.dart';
import 'home_screen.dart';

/// Contenedor principal de navegación: 4 destinos del mismo tamaño en
/// una NavigationBar estándar de Material 3.
///
/// IMPORTANTE (bug real corregido en esta ronda): Inicio, Documentos y
/// Herramientas SÍ usan IndexedStack (mantienen su estado al cambiar de
/// pestaña), pero Escanear NO -- solo se construye cuando el usuario
/// realmente entra a esa pestaña. Si Escanear también viviera dentro del
/// IndexedStack, su initState() (que pide permiso de cámara e inicia la
/// cámara) se dispararía en cuanto abre la app, sin que el usuario haya
/// pulsado "Escanear" -- justo lo que la especificación pide evitar. Al
/// salir de la pestaña, ScannerScreen se destruye por completo (su
/// dispose() libera la cámara), y se vuelve a crear limpia la próxima
/// vez que se entra.
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
    final persistentTabs = [
      HomeScreen(onNavigateToTab: _goToTab),
      const DocumentsScreen(),
      const ToolsScreen(),
    ];
    // Índices dentro de persistentTabs para cada pestaña que NO es Escanear.
    const persistentIndexFor = {0: 0, 2: 1, 3: 2};

    return Scaffold(
      body: _tabIndex == 1
          ? const ScannerScreen()
          : IndexedStack(
              index: persistentIndexFor[_tabIndex] ?? 0,
              children: persistentTabs,
            ),
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
