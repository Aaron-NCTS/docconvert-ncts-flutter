import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/document_storage_service.dart';
import '../../services/file_validation_service.dart';
import '../../services/pdf_to_word_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_dialogs.dart';
import '../../widgets/selected_file_card.dart';

/// PDF a Word: implementación real. Selecciona un PDF, lo valida por
/// firma real de contenido, muestra nombre/tamaño, permite quitarlo, y
/// convierte de verdad a DOCX (extrayendo el texto real del PDF).
///
/// Limitación honesta: si el PDF es una imagen escaneada sin texto
/// seleccionable, el servicio lo detecta y avisa -- esta versión no
/// incluye OCR todavía (eso es una fase aparte).
class PdfToWordScreen extends StatefulWidget {
  const PdfToWordScreen({super.key});

  @override
  State<PdfToWordScreen> createState() => _PdfToWordScreenState();
}

class _PdfToWordScreenState extends State<PdfToWordScreen> {
  File? _selectedFile;
  String _selectedFileName = '';
  int _selectedFileSize = 0;

  bool _isWorking = false;
  String? _statusMessage;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    final path = picked.path;
    if (path == null) return;

    final file = File(path);
    final validation = await FileValidationService.validatePdf(file);

    if (!validation.isValid) {
      if (!mounted) return;
      await FormatDialogs.showIncompatible(context, validation.message!);
      return;
    }

    setState(() {
      _selectedFile = file;
      _selectedFileName = picked.name;
      _selectedFileSize = picked.size;
      _statusMessage = null;
    });
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
      _selectedFileName = '';
      _selectedFileSize = 0;
      _statusMessage = null;
    });
  }

  Future<void> _convert() async {
    final file = _selectedFile;
    if (file == null || _isWorking) return;

    setState(() {
      _isWorking = true;
      _statusMessage = 'Iniciando conversión...';
    });

    try {
      final baseName = DocumentStorageService.sanitizeFileName(
        _selectedFileName.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
      );
      final outputPath = await DocumentStorageService.resolveUniquePath('$baseName.docx');

      await PdfToWordService.convert(
        input: file,
        outputPath: outputPath,
        onProgress: (msg) {
          if (mounted) setState(() => _statusMessage = msg);
        },
      );

      if (!mounted) return;
      setState(() {
        _isWorking = false;
        _statusMessage = null;
      });
      _removeFile();

      await FormatDialogs.showError(
        context,
        title: 'Archivo creado correctamente',
        message: 'Se guardó como:\n${outputPath.split('/').last}',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isWorking = false;
        _statusMessage = null;
      });
      await FormatDialogs.showError(
        context,
        title: 'No se pudo convertir el documento',
        message: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF a Word')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Convierte documentos PDF (con texto seleccionable) en archivos Word.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isWorking ? null : _pickFile,
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Seleccionar PDF'),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null)
              SelectedFileCard(
                fileName: _selectedFileName,
                fileSizeLabel: _formatSize(_selectedFileSize),
                statusLabel: 'Listo para convertir',
                statusColor: Theme.of(context).colorScheme.primary,
                onRemove: _removeFile,
                enabled: !_isWorking,
              )
            else
              const Expanded(
                child: EmptyState(
                  icon: Icons.picture_as_pdf_outlined,
                  title: 'Sin documento seleccionado',
                  message: 'Elige un archivo PDF para convertirlo a Word.',
                ),
              ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 12),
              Text(_statusMessage!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: (_selectedFile != null && !_isWorking) ? _convert : null,
              icon: _isWorking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.description_outlined),
              label: Text(_isWorking ? 'Convirtiendo...' : 'Convertir a Word'),
            ),
          ],
        ),
      ),
    );
  }
}
