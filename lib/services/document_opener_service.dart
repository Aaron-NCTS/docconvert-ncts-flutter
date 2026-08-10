import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../features/pdf_viewer/pdf_viewer_screen.dart';
import '../features/photo_viewer/photo_viewer_screen.dart';
import '../models/document_item.dart';
import '../widgets/format_dialogs.dart';

/// Decide CÓMO abrir un archivo creado, según su tipo:
/// - PDF: visor interno de la app (SfPdfViewer) -- nunca sale de
///   DocConvert NCTS para esto.
/// - Imagen: visor interno de la app (InteractiveViewer).
/// - DOCX: app externa instalada (Word, Google Docs, etc.), porque un
///   visor DOCX interno completo es un proyecto aparte -- ver la nota
///   honesta en pdf_to_word_service.dart y en la entrega de esta ronda.
class DocumentOpenerService {
  static Future<void> open(BuildContext context, DocumentItem item) async {
    if (!await File(item.path).exists()) {
      await FormatDialogs.showError(
        context,
        title: 'Archivo no encontrado',
        message: 'Este archivo ya no está disponible (¿se movió o se eliminó?).',
      );
      return;
    }

    if (item.isPdf) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PdfViewerScreen(path: item.path, title: item.name)),
      );
      return;
    }

    if (item.extension == 'jpg' || item.extension == 'jpeg' || item.extension == 'png' || item.extension == 'webp') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PhotoViewerScreen(path: item.path)),
      );
      return;
    }

    // DOCX (y cualquier otro tipo futuro): app externa.
    final result = await OpenFilex.open(item.path);
    if (result.type == ResultType.noAppToOpen) {
      if (!context.mounted) return;
      await FormatDialogs.showError(
        context,
        title: 'Aplicación no disponible',
        message: 'No se encontró una aplicación instalada que pueda abrir documentos Word.',
      );
    } else if (result.type != ResultType.done) {
      if (!context.mounted) return;
      await FormatDialogs.showError(
        context,
        title: 'No se pudo abrir el archivo',
        message: 'Intenta de nuevo. Si el problema continúa, comparte el archivo en su lugar.',
      );
    }
  }
}
