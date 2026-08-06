import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum PdfPageSizeOption { a4, carta }

enum PdfQualityOption { baja, media, alta }

/// Genera un PDF con una imagen por página, cada una ajustada al tamaño
/// de página elegido SIN deformarse (se centra dejando márgenes si la
/// proporción no coincide -- igual que el motor anterior en Python).
///
/// La calidad elegida SÍ afecta el resultado real: reduce la resolución
/// máxima de la imagen y la re-codifica como JPEG a ese nivel de calidad
/// antes de incrustarla -- así "Baja" produce un PDF notablemente más
/// ligero que "Alta", no solo un número decorativo en la pantalla.
class PhotoPdfService {
  static PdfPageFormat _pageFormat(PdfPageSizeOption size) {
    switch (size) {
      case PdfPageSizeOption.a4:
        return PdfPageFormat.a4;
      case PdfPageSizeOption.carta:
        return PdfPageFormat.letter;
    }
  }

  static int _jpegQuality(PdfQualityOption quality) {
    switch (quality) {
      case PdfQualityOption.baja:
        return 45;
      case PdfQualityOption.media:
        return 70;
      case PdfQualityOption.alta:
        return 90;
    }
  }

  static int _maxDimension(PdfQualityOption quality) {
    switch (quality) {
      case PdfQualityOption.baja:
        return 1000;
      case PdfQualityOption.media:
        return 1600;
      case PdfQualityOption.alta:
        return 2400;
    }
  }

  /// Crea el PDF a partir de una lista ordenada de rutas de imágenes
  /// (ya validadas por FileValidationService.validateImage antes de
  /// llegar aquí), y lo guarda en `outputPath`.
  static Future<void> createFromImages({
    required List<String> imagePaths,
    required String outputPath,
    required PdfPageSizeOption pageSize,
    required PdfQualityOption quality,
    void Function(String message)? onProgress,
  }) async {
    if (imagePaths.isEmpty) {
      throw Exception('No hay imágenes seleccionadas.');
    }

    final doc = pw.Document();
    final baseFormat = _pageFormat(pageSize);
    final maxDimension = _maxDimension(quality);
    final jpegQuality = _jpegQuality(quality);

    for (var i = 0; i < imagePaths.length; i++) {
      onProgress?.call('Procesando imagen ${i + 1} de ${imagePaths.length}...');

      final file = File(imagePaths[i]);
      if (!await file.exists()) {
        throw Exception('No se encontró la imagen ${file.path}.');
      }

      final originalBytes = await file.readAsBytes();
      var decoded = img.decodeImage(originalBytes);
      if (decoded == null) {
        throw Exception('No se pudo procesar la imagen ${file.path} (¿está dañada?).');
      }

      // Respeta la orientación EXIF real de la foto (cámaras suelen
      // guardar la imagen "acostada" con una bandera de orientación).
      decoded = img.bakeOrientation(decoded);

      // Reduce la resolución según la calidad elegida, preservando
      // proporción -- nunca la agranda si ya es más pequeña.
      if (decoded.width > maxDimension || decoded.height > maxDimension) {
        decoded = img.copyResize(
          decoded,
          width: decoded.width >= decoded.height ? maxDimension : null,
          height: decoded.height > decoded.width ? maxDimension : null,
        );
      }

      final jpegBytes = img.encodeJpg(decoded, quality: jpegQuality);
      final image = pw.MemoryImage(jpegBytes);

      final isLandscape = decoded.width > decoded.height;
      final pageFormat = isLandscape ? baseFormat.landscape : baseFormat;

      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    onProgress?.call('Guardando PDF...');
    final outFile = File(outputPath);
    await outFile.writeAsBytes(await doc.save());
  }
}
