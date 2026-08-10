/// De qué herramienta salió un archivo -- se usa para las categorías de
/// "Archivos creados" (Todos/PDF/Word/Fotos) y para elegir el ícono.
enum SourceTool { photosToPdf, wordToPdf, pdfToWord, scanner }

/// Un archivo final creado por la app (nunca un archivo de entrada ni un
/// temporal). Se guarda en JSON en el almacenamiento privado de la app --
/// mismo enfoque que ya usamos en la versión Python (history.py).
class CreatedFile {
  CreatedFile({
    required this.id,
    required this.name,
    required this.extension,
    required this.mimeType,
    required this.path,
    required this.sizeBytes,
    required this.createdAt,
    required this.sourceTool,
  });

  final String id;
  final String name;
  final String extension; // "pdf" o "docx", sin el punto
  final String mimeType;
  final String path;
  final int sizeBytes;
  final DateTime createdAt;
  final SourceTool sourceTool;

  bool get isPdf => extension.toLowerCase() == 'pdf';
  bool get isDocx => extension.toLowerCase() == 'docx';
  bool get isImage => const ['jpg', 'jpeg', 'png', 'webp'].contains(extension.toLowerCase());

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'extension': extension,
        'mimeType': mimeType,
        'path': path,
        'sizeBytes': sizeBytes,
        'createdAt': createdAt.toIso8601String(),
        'sourceTool': sourceTool.name,
      };

  factory CreatedFile.fromJson(Map<String, dynamic> json) {
    return CreatedFile(
      id: json['id'] as String,
      name: json['name'] as String,
      extension: json['extension'] as String,
      mimeType: json['mimeType'] as String,
      path: json['path'] as String,
      sizeBytes: json['sizeBytes'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      sourceTool: SourceTool.values.firstWhere(
        (t) => t.name == json['sourceTool'],
        orElse: () => SourceTool.photosToPdf,
      ),
    );
  }

  CreatedFile copyWith({String? name, String? path}) {
    return CreatedFile(
      id: id,
      name: name ?? this.name,
      extension: extension,
      mimeType: mimeType,
      path: path ?? this.path,
      sizeBytes: sizeBytes,
      createdAt: createdAt,
      sourceTool: sourceTool,
    );
  }
}
