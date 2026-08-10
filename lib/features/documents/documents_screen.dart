import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/document_item.dart';
import '../../providers/documents_provider.dart';
import '../../services/document_opener_service.dart';
import '../../services/share_service.dart';
import '../../widgets/document_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_dialogs.dart';

/// "Archivos creados": lista real y persistente, con pestañas
/// Todos / PDF / Word / Fotos. Nunca muestra archivos temporales,
/// de entrada, fallidos, rotos, o con tamaño 0 -- esa limpieza ya la
/// hace DocumentRepository.loadValid() antes de que estos datos lleguen
/// aquí.
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleRename(BuildContext context, DocumentItem item) async {
    final controller = TextEditingController(
      text: item.name.substring(0, item.name.length - item.extension.length - 1),
    );
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Renombrar archivo'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (newName == null || newName.trim().isEmpty) return;

    try {
      await context.read<DocumentsProvider>().renameItem(item.id, newName.trim());
    } catch (e) {
      if (!context.mounted) return;
      await FormatDialogs.showError(context, title: 'No se pudo renombrar', message: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _handleDelete(BuildContext context, DocumentItem item) async {
    final confirmed = await FormatDialogs.confirm(
      context,
      title: 'Eliminar archivo',
      message: '¿Quieres eliminar este archivo de forma permanente?',
      confirmLabel: 'Eliminar',
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    await context.read<DocumentsProvider>().removeItem(item.id);
  }

  void _handleInfo(BuildContext context, DocumentItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${item.name}'),
            const SizedBox(height: 6),
            Text('Tipo: ${item.mimeType}'),
            const SizedBox(height: 6),
            Text('Tamaño: ${(item.sizeBytes / 1024).toStringAsFixed(1)} KB'),
            const SizedBox(height: 6),
            Text('Creado: ${item.createdAt}'),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Entendido')),
        ],
      ),
    );
  }

  Widget _buildList(List<DocumentItem> items) {
    if (items.isEmpty) {
      return const EmptyState(
        icon: Icons.folder_open_outlined,
        title: 'Todavía no has creado documentos',
        message: 'Los archivos que conviertas o escanees aparecerán aquí.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return DocumentCard(
          item: item,
          onOpen: () => DocumentOpenerService.open(context, item),
          onShare: () => ShareService.shareFile(item.path),
          onRename: () => _handleRename(context, item),
          onDelete: () => _handleDelete(context, item),
          onInfo: () => _handleInfo(context, item),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archivos creados'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: false,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'PDF'),
            Tab(text: 'Word'),
            Tab(text: 'Fotos'),
          ],
        ),
      ),
      body: Consumer<DocumentsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(provider.items),
              _buildList(provider.pdfItems),
              _buildList(provider.docxItems),
              _buildList(provider.photoItems),
            ],
          );
        },
      ),
    );
  }
}
