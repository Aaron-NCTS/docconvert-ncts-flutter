import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/scan_page.dart';
import '../../providers/documents_provider.dart';
import '../../services/document_registration_helper.dart';
import '../../services/document_storage_service.dart';
import '../../services/photo_pdf_service.dart';
import '../../services/scan_filter_service.dart';
import '../../widgets/format_dialogs.dart';
import 'scanner_screen.dart';

const _filterLabels = {
  ScanFilter.original: 'Original',
  ScanFilter.automatico: 'Automático',
  ScanFilter.documento: 'Documento',
  ScanFilter.blancoYNegro: 'Blanco y negro',
  ScanFilter.escalaDeGrises: 'Escala de grises',
  ScanFilter.contrasteAlto: 'Contraste alto',
};

/// Manejo de las páginas escaneadas: agregar otra, reordenar, girar,
/// cambiar filtro, eliminar, y crear el PDF final -- reutiliza
/// PhotoPdfService (el mismo motor de Fotos a PDF) para el PDF final,
/// en vez de duplicar esa lógica.
class ScanPagesScreen extends StatefulWidget {
  const ScanPagesScreen({super.key, required this.firstPagePath});

  final String firstPagePath;

  @override
  State<ScanPagesScreen> createState() => _ScanPagesScreenState();
}

class _ScanPagesScreenState extends State<ScanPagesScreen> {
  late final List<ScanPage> _pages = [ScanPage(processedPath: widget.firstPagePath)];
  final TextEditingController _nameController = TextEditingController();
  bool _isWorking = false;
  String? _statusMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addPage() async {
    final newPath = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const _CaptureOnlyRoute()),
    );
    if (newPath == null) return;
    setState(() => _pages.add(ScanPage(processedPath: newPath)));
  }

  Future<void> _rotate(ScanPage page) async {
    setState(() => _statusMessage = 'Girando...');
    try {
      final newPath = await PhotoPdfService.rotate90(page.processedPath);
      setState(() {
        page.processedPath = newPath;
        _statusMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusMessage = null);
    }
  }

  Future<void> _applyFilter(ScanPage page, ScanFilter filter) async {
    setState(() => _statusMessage = 'Aplicando filtro...');
    try {
      final bytes = await ScanFilterService.applyFilter(page.processedPath, filter);
      final newPath = '${page.processedPath}_f${filter.index}.jpg';
      await File(newPath).writeAsBytes(bytes);
      setState(() {
        page.processedPath = newPath;
        page.filter = filter;
        _statusMessage = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statusMessage = null);
    }
  }

  void _removePage(String id) {
    if (_pages.length == 1) return; // siempre debe quedar al menos 1 página
    setState(() => _pages.removeWhere((p) => p.id == id));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _pages.removeAt(oldIndex);
      _pages.insert(newIndex, item);
    });
  }

  Future<void> _createPdf() async {
    if (_isWorking) return;
    setState(() {
      _isWorking = true;
      _statusMessage = 'Creando PDF...';
    });

    try {
      final rawName = DocumentStorageService.sanitizeFileName(
        _nameController.text.isEmpty ? 'Documento escaneado' : _nameController.text,
        fallback: 'Documento escaneado',
      );
      final fileName = rawName.toLowerCase().endsWith('.pdf') ? rawName : '$rawName.pdf';
      final outputPath = await DocumentStorageService.resolveUniquePath(fileName);

      await PhotoPdfService.createFromImages(
        imagePaths: _pages.map((p) => p.processedPath).toList(),
        outputPath: outputPath,
        pageSize: PdfPageSizeOption.carta,
        quality: PdfQualityOption.alta,
        onProgress: (msg) {
          if (mounted) setState(() => _statusMessage = msg);
        },
      );

      final registered = await DocumentRegistrationHelper.fromCreatedFile(path: outputPath, tool: 'scanner');
      if (!mounted) return;
      await context.read<DocumentsProvider>().registerCreatedFile(registered);

      if (!mounted) return;
      await FormatDialogs.showError(
        context,
        title: 'Documento creado correctamente',
        message: 'Se guardó como:\n${outputPath.split('/').last}\n\nYa aparece en "Archivos creados".',
      );
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWorking = false;
        _statusMessage = null;
      });
      await FormatDialogs.showError(
        context,
        title: 'No se pudo crear el PDF',
        message: 'Intenta de nuevo.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Escanear (${_pages.length} página${_pages.length == 1 ? '' : 's'})')),
      body: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pages.length,
              // ignore: deprecated_member_use
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final page = _pages[index];
                return Card(
                  key: ValueKey(page.id),
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(File(page.processedPath), width: 56, height: 72, fit: BoxFit.cover),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Página ${index + 1}', style: Theme.of(context).textTheme.bodyMedium),
                              Text(
                                _filterLabels[page.filter]!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        PopupMenuButton<ScanFilter>(
                          icon: const Icon(Icons.filter_alt_outlined),
                          onSelected: (filter) => _applyFilter(page, filter),
                          itemBuilder: (context) => ScanFilter.values
                              .map((f) => PopupMenuItem(value: f, child: Text(_filterLabels[f]!)))
                              .toList(),
                        ),
                        IconButton(
                          onPressed: () => _rotate(page),
                          icon: const Icon(Icons.rotate_right_outlined),
                        ),
                        IconButton(
                          onPressed: _pages.length > 1 ? () => _removePage(page.id) : null,
                          icon: const Icon(Icons.delete_outline),
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isWorking ? null : _addPage,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Agregar página'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    enabled: !_isWorking,
                    decoration: const InputDecoration(labelText: 'Nombre del documento (opcional)'),
                  ),
                  if (_statusMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(_statusMessage!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isWorking ? null : _createPdf,
                    icon: _isWorking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(_isWorking ? 'Creando PDF...' : 'Crear PDF'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ruta auxiliar mínima para "Agregar página": reutiliza el flujo de
/// captura + recorte de ScannerScreen con returnPathOnly=true, para que
/// regrese directo con la ruta de la nueva página en vez de navegar a
/// ScanPagesScreen otra vez (evita anidar la misma pantalla dentro de
/// sí misma).
class _CaptureOnlyRoute extends StatelessWidget {
  const _CaptureOnlyRoute();

  @override
  Widget build(BuildContext context) {
    return const ScannerScreen(returnPathOnly: true);
  }
}
