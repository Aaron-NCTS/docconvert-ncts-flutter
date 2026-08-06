import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// "Mis documentos": en esta Fase 1 solo la estructura visual (AppBar +
/// estado vacío). Buscar/filtrar/ordenar y la lista real de documentos se
/// implementan en la Fase 2, cuando exista persistencia real.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis documentos'),
      ),
      body: const EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'Todavía no has creado documentos',
        message: 'Los archivos que conviertas o escanees aparecerán aquí.',
      ),
    );
  }
}
