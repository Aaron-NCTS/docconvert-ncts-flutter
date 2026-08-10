import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Recorta una imagen a un rectángulo (en coordenadas de pixel reales de
/// la imagen, no de la pantalla). El llamador es responsable de convertir
/// las coordenadas de la interfaz a coordenadas de imagen antes de llamar
/// aquí -- ver scan_crop_screen.dart.
class ScanCropService {
  static Future<Uint8List> crop(String sourcePath, int x, int y, int width, int height) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('No se pudo procesar la imagen para recortarla.');
    }

    final safeX = x.clamp(0, decoded.width - 1);
    final safeY = y.clamp(0, decoded.height - 1);
    final safeWidth = width.clamp(1, decoded.width - safeX);
    final safeHeight = height.clamp(1, decoded.height - safeY);

    final cropped = img.copyCrop(decoded, x: safeX, y: safeY, width: safeWidth, height: safeHeight);
    return img.encodeJpg(cropped, quality: 92);
  }
}
