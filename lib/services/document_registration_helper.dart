import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/document_item.dart';

/// Construye un DocumentItem real a partir de un archivo que una
/// herramienta acaba de crear -- lee su tamaño real del disco (nunca
/// asume), en vez de simplemente reportar lo que se esperaba escribir.
class DocumentRegistrationHelper {
  static Future<DocumentItem> fromCreatedFile({
    required String path,
    required String tool,
  }) async {
    final file = File(path);
    final size = await file.length();
    final ext = p.extension(path).replaceFirst('.', '').toLowerCase();

    final mimeType = ext == 'pdf'
        ? 'application/pdf'
        : 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';

    return DocumentItem(
      id: const Uuid().v4(),
      name: p.basename(path),
      path: path,
      extension: ext,
      mimeType: mimeType,
      sizeBytes: size,
      createdAt: DateTime.now(),
      tool: tool,
    );
  }
}
