import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/documents_provider.dart';
import '../../services/document_registration_helper.dart';
import '../../services/document_storage_service.dart';
import '../../services/file_validation_service.dart';
import '../../services/word_to_pdf_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_dialogs.dart';
import '../../widgets/selected_file_card.dart';

/// Word a PDF: implementación real. El resultado ya se registra en
/// "Archivos creados" (antes quedaba aislado solo en esta pantalla).
class WordToPdfScreen extends StatefulWidget {
  const WordToPdfScreen({super.key});

  @override
  State<WordToPdfScreen> createState() => _WordToPdfScreenState();
}

class _WordToPdfScreenState extends State<WordToPdfScreen> {
  File? _selectedFile;
  String _selectedFileName = '';
  int _selectedFileSize = 0;

  bool _isWorking = false;
  String? _statusMessage;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['docx'],
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    final path = picked.path;
    if (path == null) return;

    final file = File(path);
    final validation = await FileValidationService.validateDocx(file);

    if (!validation.isValid) {
      if (!mounted) return;
      await FormatDialogs.showIncompatible(context, 'Selecciona un documento DOCX válido.');
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
        _selectedFileName.replaceAll(RegExp(r'\.docx$', caseSensitive: false), ''),
      );
      final outputPath = await DocumentStorageService.resolveUniquePath('$baseName.pdf');

      await WordToPdfService.convert(
        input: file,
        outputPath: outputPath,
        onProgress: (msg) {
          if (mounted) setState(() => _statusMessage = msg);
        },
      );

      final registered = await DocumentRegistrationHelper.fromCreatedFile(
        path: outputPath,
        tool: 'word_to_pdf',
      );
      if (!mounted) return;
      await context.read<DocumentsProvider>().registerCreatedFile(registered);

      setState(() {
        _isWorking = false;
        _statusMessage = null;
      });
      _removeFile();

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
      appBar: AppBar(title: const Text('Word a PDF')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Convierte documentos Word (DOCX) en archivos PDF.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isWorking ? null : _pickFile,
              icon: const Icon(Icons.description_outlined),
              label: const Text('Seleccionar documento Word'),
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
                  icon: Icons.description_outlined,
                  title: 'Sin documento seleccionado',
                  message: 'Elige un archivo DOCX para convertirlo a PDF.',
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
                  : const Icon(Icons.picture_as_pdf_outlined),
              label: Text(_isWorking ? 'Convirtiendo...' : 'Convertir a PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
