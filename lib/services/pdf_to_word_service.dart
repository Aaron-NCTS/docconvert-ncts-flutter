import 'dart:io';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'docx_writer_service.dart';

/// Convierte un PDF ya validado a DOCX.
///
/// Usa Syncfusion (`syncfusion_flutter_pdf`) para extraer el texto real
/// del PDF -- es la única pieza de este proyecto que depende de una
/// librería de un tercero para el formato, porque no existe una opción
/// puramente en Dart tan robusta como la que usamos para DOCX/PDF de
/// salida (decisión ya conversada contigo).
///
/// Limitación honesta: extrae texto plano por página, sin conservar el
/// diseño visual original (columnas, tablas, imágenes). Si el PDF es en
/// realidad una imagen escaneada (sin texto seleccionable), lo detecta y
/// avisa en vez de generar un DOCX vacío silenciosamente.
class PdfToWordService {
  static Future<void> convert({
    required File input,
    required String outputPath,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Leyendo el PDF...');
    final bytes = await input.readAsBytes();

    final PdfDocument document;
    try {
      document = PdfDocument(inputBytes: bytes);
    } catch (e) {
      throw Exception('No se pudo leer el documento. Puede estar dañado o protegido con contraseña.');
    }

    try {
      final extractor = PdfTextExtractor(document);
      final paragraphs = <String>[];

      for (var pageIndex = 0; pageIndex < document.pages.count; pageIndex++) {
        onProgress?.call('Extrayendo texto: página ${pageIndex + 1} de ${document.pages.count}...');
        final pageText = extractor.extractText(startPageIndex: pageIndex, endPageIndex: pageIndex);
        for (final line in pageText.split('\n')) {
          if (line.trim().isNotEmpty) {
            paragraphs.add(line.trim());
          }
        }
      }

      if (paragraphs.isEmpty) {
        throw Exception(
          'Este PDF parece ser un documento escaneado (sin texto seleccionable). '
          'Esta versión no incluye OCR todavía.',
        );
      }

      onProgress?.call('Guardando documento Word...');
      await DocxWriterService.write(paragraphs: paragraphs, outputPath: outputPath);
    } finally {
      document.dispose();
    }
  }
}
