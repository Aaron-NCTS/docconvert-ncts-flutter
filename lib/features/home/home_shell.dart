import 'package:flutter/material.dart';

import '../documents/documents_screen.dart';
import '../scanner/scanner_screen.dart';
import '../tools/tools_screen.dart';
import 'home_screen.dart';

/// Contenedor principal de navegación: 3 pestañas persistentes (Inicio,
/// Documentos, Herramientas) + el botón de Escanear, que pedías con mayor
/// protagonismo -- aquí se implementa como un FloatingActionButton grande
/// centrado sobre una barra inferior con muesca, en vez de un cuarto ícono
/// más entre los demás.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tabIndex = 0;

  static const _tabs = [
    HomeScreen(),
    DocumentsScreen(),
    ToolsScreen(),
  ];

  void _openScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tabIndex, children: _tabs),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.large(
        onPressed: _openScanner,
        tooltip: 'Escanear',
        child: const Icon(Icons.document_scanner_outlined, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Inicio',
              selected: _tabIndex == 0,
              onTap: () => setState(() => _tabIndex = 0),
            ),
            _NavItem(
              icon: Icons.folder_outlined,
              selectedIcon: Icons.folder,
              label: 'Documentos',
              selected: _tabIndex == 1,
              onTap: () => setState(() => _tabIndex = 1),
            ),
            // Espacio reservado para que el FAB centrado no se encime con
            // los botones (la muesca de BottomAppBar ya deja el hueco
            // visual, esto solo separa los grupos de botones).
            const SizedBox(width: 56),
            _NavItem(
              icon: Icons.build_outlined,
              selectedIcon: Icons.build,
              label: 'Herramientas',
              selected: _tabIndex == 2,
              onTap: () => setState(() => _tabIndex = 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? selectedIcon : icon, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
