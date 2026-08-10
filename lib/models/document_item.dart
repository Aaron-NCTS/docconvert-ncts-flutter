/// Un archivo generado por alguna herramienta de DocConvert NCTS,
/// registrado en la persistencia local para aparecer en "Archivos
/// creados" (Inicio y la pantalla completa de Documentos).
class DocumentItem {
  DocumentItem({
    required this.id,
    required this.name,
    required this.path,
    required this.extension,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    required this.tool,
  });

  final String id;
  final String name;
  final String path;
  final String extension; // "pdf" o "docx", sin el punto
  final String mimeType;
  final int sizeBytes;
  final DateTime createdAt;

  /// Qué herramienta lo generó: 'photos_to_pdf', 'word_to_pdf',
  /// 'pdf_to_word', o 'scanner'. Se usa para las categorías de filtro
  /// (PDF / Word / Fotos) en la pantalla de Documentos.
  final String tool;

  bool get isPdf => extension == 'pdf';
  bool get isDocx => extension == 'docx';
  bool get isFromPhotos => tool == 'photos_to_pdf' || tool == 'scanner';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'path': path,
        'extension': extension,
        'mimeType': mimeType,
        'sizeBytes': sizeBytes,
        'createdAt': createdAt.toIso8601String(),
        'tool': tool,
      };

  factory DocumentItem.fromJson(Map<String, dynamic> json) {
    return DocumentItem(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      extension: json['extension'] as String,
      mimeType: json['mimeType'] as String,
      sizeBytes: json['sizeBytes'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tool: json['tool'] as String,
    );
  }

  DocumentItem copyWith({String? name, String? path}) {
    return DocumentItem(
      id: id,
      name: name ?? this.name,
      path: path ?? this.path,
      extension: extension,
      mimeType: mimeType,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
      tool: tool,
    );
  }
}
