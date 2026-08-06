import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Dónde y cómo se guardan los archivos que la app genera.
///
/// En esta fase se guardan en la carpeta de documentos propia de la app
/// (privada, administrada por Android) -- exponerlos en "Mis documentos"
/// del sistema, o en una carpeta pública de Descargas, es parte de la
/// Fase 2 (persistencia + compartir/abrir), cuando también se agregue el
/// registro en la base de datos local.
class DocumentStorageService {
  static Future<Directory> _outputDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'DocConvert NCTS'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Regresa una ruta de salida que no choca con un archivo existente,
  /// agregando " (1)", " (2)", etc. si hace falta -- igual que en la
  /// versión anterior de esta app.
  static Future<String> resolveUniquePath(String fileName) async {
    final dir = await _outputDirectory();
    final ext = p.extension(fileName);
    final base = p.basenameWithoutExtension(fileName);

    var candidate = fileName;
    var counter = 1;
    while (await File(p.join(dir.path, candidate)).exists()) {
      candidate = '$base ($counter)$ext';
      counter++;
    }
    return p.join(dir.path, candidate);
  }

  /// Sanitiza un nombre de archivo elegido por el usuario: quita
  /// caracteres inválidos en Android/Windows y evita nombres vacíos.
  static String sanitizeFileName(String name, {String fallback = 'documento'}) {
    final trimmed = name.trim();
    final cleaned = trimmed.replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();
    return cleaned.isEmpty ? fallback : cleaned;
  }
}
