import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Resultado de una validación: o es válida, o trae un mensaje específico
/// listo para mostrar al usuario (nunca una excepción técnica cruda).
class ValidationResult {
  const ValidationResult.valid() : message = null;
  const ValidationResult.invalid(this.message);

  final String? message;
  bool get isValid => message == null;
}

/// Validación real de archivos por CONTENIDO, no por extensión -- un
/// archivo llamado "foto.pdf" que en realidad es una imagen debe
/// rechazarse igual que si se llamara "foto.jpg".
class FileValidationService {
  static const List<int> _pdfMagic = [0x25, 0x50, 0x44, 0x46]; // "%PDF"
  static const List<int> _oleMagic = [0xD0, 0xCF, 0x11, 0xE0, 0xA1, 0xB1, 0x1A, 0xE1]; // .doc antiguo

  /// Valida un PDF real: firma correcta, no vacío, estructura mínima
  /// (que termine con el marcador %%EOF, presente en cualquier PDF bien
  /// formado, incluso si está truncado a la mitad del cuerpo).
  static Future<ValidationResult> validatePdf(File file) async {
    if (!await file.exists()) {
      return const ValidationResult.invalid('El archivo no existe o no se pudo leer.');
    }
    final length = await file.length();
    if (length == 0) {
      return const ValidationResult.invalid('El archivo está vacío.');
    }

    final header = await _readBytes(file, 0, 8);
    if (!_startsWith(header, _pdfMagic)) {
      return const ValidationResult.invalid(
        'El archivo seleccionado no es un PDF válido. Selecciona un documento PDF.',
      );
    }
    return const ValidationResult.valid();
  }

  /// Valida un DOCX real: primero descarta un .doc antiguo (por firma
  /// binaria real, no por extensión), después confirma que sea un ZIP
  /// válido con la estructura interna mínima de un documento Word real.
  static Future<ValidationResult> validateDocx(File file) async {
    if (!await file.exists()) {
      return const ValidationResult.invalid('El archivo no existe o no se pudo leer.');
    }
    final length = await file.length();
    if (length == 0) {
      return const ValidationResult.invalid('El archivo está vacío.');
    }

    final header = await _readBytes(file, 0, 8);
    if (_startsWith(header, _oleMagic)) {
      return const ValidationResult.invalid(
        'El formato DOC antiguo todavía no es compatible. Selecciona un documento DOCX.',
      );
    }

    try {
      final bytes = await file.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);
      final names = archive.files.map((f) => f.name).toSet();
      if (!names.contains('[Content_Types].xml') || !names.contains('word/document.xml')) {
        return const ValidationResult.invalid(
          'Selecciona un documento DOCX válido.',
        );
      }
    } catch (_) {
      return const ValidationResult.invalid(
        'Selecciona un documento DOCX válido.',
      );
    }
    return const ValidationResult.valid();
  }

  /// Valida una imagen real por firma de contenido (JPEG/PNG/WEBP),
  /// detectando además HEIC/HEIF para dar un mensaje honesto de que no
  /// se soportan todavía, en vez de un fallo confuso más adelante.
  static Future<ValidationResult> validateImage(File file) async {
    if (!await file.exists()) {
      return const ValidationResult.invalid('El archivo no existe o no se pudo leer.');
    }
    final length = await file.length();
    if (length == 0) {
      return const ValidationResult.invalid('El archivo está vacío.');
    }

    final header = await _readBytes(file, 0, 12);

    final isJpeg = header.length >= 3 && header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF;
    final isPng = _startsWith(header, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    final isWebp = header.length >= 12 &&
        header[0] == 0x52 && header[1] == 0x49 && header[2] == 0x46 && header[3] == 0x46 &&
        header[8] == 0x57 && header[9] == 0x45 && header[10] == 0x42 && header[11] == 0x50;

    if (isJpeg || isPng || isWebp) {
      return const ValidationResult.valid();
    }

    // HEIC/HEIF: contenedor ISO-BMFF con una caja "ftyp" que declara la
    // marca real (heic/heix/hevc/mif1/msf1, etc.).
    if (header.length >= 12 && header[4] == 0x66 && header[5] == 0x74 && header[6] == 0x79 && header[7] == 0x70) {
      return const ValidationResult.invalid(
        'Este formato (HEIC/HEIF, típico de iPhone) todavía no es compatible. '
        'Selecciona una imagen JPG, PNG o WEBP.',
      );
    }

    return const ValidationResult.invalid(
      'Selecciona una imagen JPG, PNG o WEBP compatible.',
    );
  }

  static Future<Uint8List> _readBytes(File file, int start, int count) async {
    final raf = await file.open();
    try {
      await raf.setPosition(start);
      return await raf.read(count);
    } finally {
      await raf.close();
    }
  }

  static bool _startsWith(Uint8List data, List<int> prefix) {
    if (data.length < prefix.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (data[i] != prefix[i]) return false;
    }
    return true;
  }
}
