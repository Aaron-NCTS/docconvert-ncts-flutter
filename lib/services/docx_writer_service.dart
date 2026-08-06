import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

const _wNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

/// Escribe un .docx simple (un párrafo de texto plano por línea) usando
/// SOLO `archive` -- un DOCX es, en el fondo, un ZIP con un puñado de
/// archivos XML fijos adentro. Mismo enfoque que docx_lite.py en la
/// versión Python de este proyecto.
class DocxWriterService {
  static Future<void> write({
    required List<String> paragraphs,
    required String outputPath,
  }) async {
    final paragraphsXml = paragraphs.map((text) {
      final safe = _escapeXml(text);
      return '<w:p><w:r><w:t xml:space="preserve">$safe</w:t></w:r></w:p>';
    }).join('\n');

    final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="$_wNs">
<w:body>
$paragraphsXml
<w:sectPr/>
</w:body>
</w:document>''';

    const contentTypesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
</Types>''';

    const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>''';

    final archive = Archive();
    _addTextFile(archive, '[Content_Types].xml', contentTypesXml);
    _addTextFile(archive, '_rels/.rels', relsXml);
    _addTextFile(archive, 'word/document.xml', documentXml);

    final zipBytes = ZipEncoder().encode(archive);
    if (zipBytes == null) {
      throw Exception('No se pudo generar el archivo DOCX (error al comprimir).');
    }
    await File(outputPath).writeAsBytes(zipBytes);
  }

  static void _addTextFile(Archive archive, String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  static String _escapeXml(String text) {
    return text.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
  }
}
