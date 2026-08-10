import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/document_item.dart';

/// Persistencia real de los archivos creados por la app.
///
/// Decisión de diseño: se guarda un archivo JSON simple (una lista de
/// registros) en vez de una base de datos con generación de código
/// (como Hive/Isar) -- en este entorno no puedo ejecutar
/// `build_runner` para generar y verificar adaptadores, así que un
/// JSON de lectura/escritura directa es la opción que puedo garantizar
/// correcta sin poder compilar por mi cuenta. Para el volumen de
/// documentos de esta app (decenas, no miles), esto es más que
/// suficiente -- no es una limitación real de rendimiento.
class DocumentRepository {
  static const _fileName = 'documentos.json';

  Future<File> _indexFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  /// Carga el índice, validando cada registro contra el disco real:
  /// si el archivo ya no existe, no se puede leer, o quedó con tamaño 0,
  /// el registro se descarta en silencio (nunca se muestra una tarjeta
  /// de "No disponible" -- si no es válido, simplemente no aparece).
  Future<List<DocumentItem>> loadValid() async {
    File file;
    try {
      file = await _indexFile();
    } catch (_) {
      // path_provider puede no tener canal de plataforma disponible
      // (esto pasa siempre en pruebas de widgets, y en teoría también
      // podría fallar en un dispositivo real en un estado raro) -- se
      // trata igual que "todavía no hay documentos", en vez de
      // propagar una excepción sin control.
      return [];
    }
    if (!await file.exists()) return [];

    List<dynamic> raw;
    try {
      final content = await file.readAsString();
      raw = jsonDecode(content) as List<dynamic>;
    } catch (_) {
      // Índice corrupto: se trata como si no hubiera documentos, en vez
      // de tronar la app entera por un archivo de metadatos dañado.
      return [];
    }

    final valid = <DocumentItem>[];
    var anyInvalid = false;

    for (final entry in raw) {
      try {
        final item = DocumentItem.fromJson(entry as Map<String, dynamic>);
        final targetFile = File(item.path);
        if (await targetFile.exists() && await targetFile.length() > 0) {
          valid.add(item);
        } else {
          anyInvalid = true;
        }
      } catch (_) {
        anyInvalid = true;
      }
    }

    valid.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (anyInvalid) {
      await _writeAll(valid);
    }
    return valid;
  }

  Future<void> add(DocumentItem item) async {
    final current = await loadValid();
    current.insert(0, item);
    await _writeAll(current);
  }

  Future<void> remove(String id) async {
    final current = await loadValid();
    final target = current.firstWhere((d) => d.id == id, orElse: () => throw Exception('no encontrado'));
    try {
      final file = File(target.path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Si el archivo físico ya no existía, no es un error real -- de
      // cualquier forma se quita del índice abajo.
    }
    current.removeWhere((d) => d.id == id);
  await _writeAll(current);
  }

  /// Renombra el archivo fisico Y actualiza el registro. Conserva la
  /// extensión original y evita nombres vacíos o inválidos.
  Future<DocumentItem> rename(String id, String newBaseName) async {
    final current = await loadValid();
    final index = current.indexWhere((d) => d.id == id);
    if (index == -1) throw Exception('Documento no encontrado.');

    final item = current[index];
    final cleaned = newBaseName.trim().replaceAll(RegExp(r'[<>:"/\\|?*]'), '').trim();
    if (cleaned.isEmpty) {
      throw Exception('El nombre no puede estar vacío.');
    }

    final dir = p.dirname(item.path);
    var candidate = '$cleaned.${item.extension}';
    var counter = 1;
    while (await File(p.join(dir, candidate)).exists() && candidate != p.basename(item.path)) {
      candidate = '$cleaned ($counter).${item.extension}';
      counter++;
    }

    final newPath = p.join(dir, candidate);
    if (newPath != item.path) {
      await File(item.path).rename(newPath);
    }

    final updated = item.copyWith(name: candidate, path: newPath);
    current[index] = updated;
    await _writeAll(current);
    return updated;
  }

  Future<void> _writeAll(List<DocumentItem> items) async {
    final file = await _indexFile();
    final jsonList = items.map((d) => d.toJson()).toList();
    await file.writeAsString(jsonEncode(jsonList));
  }
}
