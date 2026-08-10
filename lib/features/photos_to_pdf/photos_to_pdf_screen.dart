import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../providers/documents_provider.dart';
import '../../services/document_registration_helper.dart';
import '../../services/document_storage_service.dart';
import '../../services/file_validation_service.dart';
import '../../services/photo_pdf_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_dialogs.dart';

class _SelectedPhoto {
  _SelectedPhoto(this.path) : id = const Uuid().v4();
  final String id;
  String path; // puede cambiar al girar (se reescribe el archivo temporal)
}

/// Fotos a PDF: implementación real y completa.
///
/// Cambios de esta ronda:
/// - El botón "Crear PDF" ya no queda pegado al borde inferior (se
///   agregó SafeArea + margen inferior real, en vez de solo padding).
/// - El resultado ya se registra de verdad en "Archivos creados" (antes
///   solo se guardaba en disco y se mostraba un mensaje, sin aparecer en
///   ningún lado más).
class PhotosToPdfScreen extends StatefulWidget {
  const PhotosToPdfScreen({super.key});

  @override
  State<PhotosToPdfScreen> createState() => _PhotosToPdfScreenState();
}

class _PhotosToPdfScreenState extends State<PhotosToPdfScreen> {
  final List<_SelectedPhoto> _photos = [];
  final TextEditingController _nameController = TextEditingController();

  PdfPageSizeOption _pageSize = PdfPageSizeOption.carta;
  PdfQualityOption _quality = PdfQualityOption.media;

  bool _isWorking = false;
  String? _statusMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null) return;

    final rejected = <String>[];
    var added = 0;

    for (final picked in result.files) {
      final path = picked.path;
      if (path == null) continue;
      if (_photos.any((p) => p.path == path)) continue;

      final file = File(path);
      final validation = await FileValidationService.validateImage(file);
      if (!validation.isValid) {
        rejected.add(picked.name);
        continue;
      }

      setState(() => _photos.add(_SelectedPhoto(path)));
      added++;
    }

    if (!mounted) return;

    if (rejected.isNotEmpty && added == 0 && result.files.length == 1) {
      await FormatDialogs.showIncompatible(context, 'Selecciona una imagen compatible.');
    } else if (rejected.isNotEmpty) {
      setState(() {
        _statusMessage =
            '$added imagen(es) agregada(s). ${rejected.length} archivo(s) no son imágenes compatibles: ${rejected.join(', ')}';
      });
    } else if (added > 0) {
      setState(() => _statusMessage = '$added foto(s) agregada(s).');
    }
  }

  void _removeAt(String id) {
    setState(() => _photos.removeWhere((p) => p.id == id));
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, item);
    });
  }

  Future<void> _rotate(_SelectedPhoto photo) async {
    setState(() => _statusMessage = 'Girando foto...');
    try {
      final newPath = await PhotoPdfService.rotate90(photo.path);
      setState(() {
        photo.path = newPath;
        _statusMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = null);
      await FormatDialogs.showError(context, title: 'No se pudo girar la foto', message: 'Intenta de nuevo.');
    }
  }

  Future<void> _createPdf() async {
    if (_photos.isEmpty || _isWorking) return;

    setState(() {
      _isWorking = true;
      _statusMessage = 'Iniciando...';
    });

    try {
      final rawName = DocumentStorageService.sanitizeFileName(
        _nameController.text.isEmpty ? 'Fotos a PDF' : _nameController.text,
        fallback: 'Fotos a PDF',
      );
      final fileName = rawName.toLowerCase().endsWith('.pdf') ? rawName : '$rawName.pdf';
      final outputPath = await DocumentStorageService.resolveUniquePath(fileName);

      await PhotoPdfService.createFromImages(
        imagePaths: _photos.map((p) => p.path).toList(),
        outputPath: outputPath,
        pageSize: _pageSize,
        quality: _quality,
        onProgress: (msg) {
          if (mounted) setState(() => _statusMessage = msg);
        },
      );

      final registered = await DocumentRegistrationHelper.fromCreatedFile(
        path: outputPath,
        tool: 'photos_to_pdf',
      );
      if (!mounted) return;
      await context.read<DocumentsProvider>().registerCreatedFile(registered);

      setState(() {
        _photos.clear();
        _nameController.clear();
        _statusMessage = null;
        _isWorking = false;
      });

      if (!mounted) return;
      await FormatDialogs.showError(
        context,
        title: 'Archivo creado correctamente',
        message: 'Se guardó como:\n${outputPath.split('/').last}\n\nYa aparece en "Archivos creados".',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWorking = false;
        _statusMessage = null;
      });
      await FormatDialogs.showError(
        context,
        title: 'No se pudo crear el PDF',
        message: 'Intenta quitar la última foto agregada y vuelve a intentar.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(title: const Text('Fotos a PDF')),
      body: SafeArea(
        // "top: false" porque el AppBar ya cubre la parte de arriba;
        // lo que importa aquí es el margen INFERIOR real del sistema
        // (barra de gestos/botones de Android), que es justo lo que
        // pediste corregir.
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _isWorking ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Elegir fotos'),
              ),
            ),
            if (_photos.isEmpty)
              const Expanded(
                child: EmptyState(
                  icon: Icons.photo_library_outlined,
                  title: 'Agrega una o varias fotografías',
                  message: 'Selecciona imágenes JPG, PNG o WEBP para comenzar.',
                ),
              )
            else ...[
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _photos.length,
                  // onReorderItem es muy reciente (Flutter 3.41+); se
                  // mantiene onReorder por ahora para no arriesgar una
                  // firma que no puedo probar en este entorno sin
                  // Flutter instalado.
                  // ignore: deprecated_member_use
                  onReorder: _isWorking ? (_, __) {} : _reorder,
                  itemBuilder: (context, index) {
                    final photo = _photos[index];
                    return Card(
                      key: ValueKey(photo.id),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.file(
                                File(photo.path),
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text('Foto ${index + 1}', style: Theme.of(context).textTheme.bodyMedium),
                            ),
                            IconButton(
                              onPressed: _isWorking ? null : () => _rotate(photo),
                              icon: const Icon(Icons.rotate_right_outlined),
                              tooltip: 'Girar',
                            ),
                            const Icon(Icons.drag_handle),
                            IconButton(
                              onPressed: _isWorking ? null : () => _removeAt(photo.id),
                              icon: const Icon(Icons.delete_outline),
                              color: colorScheme.error,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Bloque inferior fijo: selectores + nombre + contador +
              // botón, con margen de seguridad real al final (no solo
              // padding fijo), para que el botón nunca quede pegado ni
              // tapado por la barra de navegación de Android.
              Container(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomSafeArea),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<PdfPageSizeOption>(
                      segments: const [
                        ButtonSegment(value: PdfPageSizeOption.a4, label: Text('A4')),
                        ButtonSegment(value: PdfPageSizeOption.carta, label: Text('Carta')),
                      ],
                      selected: {_pageSize},
                      onSelectionChanged: _isWorking ? null : (s) => setState(() => _pageSize = s.first),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<PdfQualityOption>(
                      segments: const [
                        ButtonSegment(value: PdfQualityOption.baja, label: Text('Baja')),
                        ButtonSegment(value: PdfQualityOption.media, label: Text('Media')),
                        ButtonSegment(value: PdfQualityOption.alta, label: Text('Alta')),
                      ],
                      selected: {_quality},
                      onSelectionChanged: _isWorking ? null : (s) => setState(() => _quality = s.first),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      enabled: !_isWorking,
                      decoration: const InputDecoration(labelText: 'Nombre del PDF (opcional)'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_photos.length} foto(s) seleccionada(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 6),
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
            ],
          ],
        ),
      ),
    );
  }
}
