import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/scan_page.dart';

/// Aplica los filtros de escaneo usando SOLO el paquete `image` (ya es
/// dependencia del proyecto, Dart puro, sin código nativo nuevo).
///
/// Aviso honesto sobre el alcance de "Automático" y "Documento": son
/// ajustes reales de brillo/contraste/blanco-y-negro (no placebo), pero
/// NO son un algoritmo de "detección inteligente de documento" con
/// visión por computadora -- eso necesitaría una librería de CV real
/// (ver la nota completa sobre el escáner en la entrega de esta ronda).
class ScanFilterService {
  static Future<Uint8List> applyFilter(String sourcePath, ScanFilter filter) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('No se pudo procesar la imagen.');
    }

    img.Image result;
    switch (filter) {
      case ScanFilter.original:
        result = decoded;
      case ScanFilter.escalaDeGrises:
        result = img.grayscale(decoded);
      case ScanFilter.contrasteAlto:
        result = img.adjustColor(decoded, contrast: 1.4, saturation: 0.9);
      case ScanFilter.automatico:
        // Ajuste automático simple: un poco más de contraste y brillo,
        // pensado para que texto en papel se vea más limpio sin
        // "quemar" la imagen -- no es una calibración por documento.
        result = img.adjustColor(decoded, contrast: 1.15, brightness: 1.05);
      case ScanFilter.documento:
        result = img.adjustColor(img.grayscale(decoded), contrast: 1.3);
      case ScanFilter.blancoYNegro:
        result = _threshold(img.grayscale(decoded));
    }

    return img.encodeJpg(result, quality: 92);
  }

  /// Binarización simple: cada pixel se vuelve blanco o negro según si
  /// su luminancia supera un umbral -- suficiente para texto con buen
  /// contraste; documentos con sombras fuertes pueden perder detalle
  /// (limitación real de un umbral fijo, no de una imagen chica).
  static img.Image _threshold(img.Image grayscaleImage) {
    const threshold = 150;
    final out = img.Image.from(grayscaleImage);
    for (var y = 0; y < out.height; y++) {
      for (var x = 0; x < out.width; x++) {
        final pixel = out.getPixel(x, y);
        final luminance = pixel.r; // ya es escala de grises: r=g=b
        final value = luminance > threshold ? 255 : 0;
        out.setPixelRgba(x, y, value, value, value, 255);
      }
    }
    return out;
  }
}
