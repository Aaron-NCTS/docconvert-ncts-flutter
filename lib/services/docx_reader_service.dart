import 'dart:io';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

const _wNs = 'http://schemas.openxmlformats.org/wordprocessingml/2006/main';

class DocxRun {
  DocxRun({required this.text, this.bold = false, this.italic = false});
  final String text;
  final bool bold;
  final bool italic;
}

class DocxParagraph {
  DocxParagraph({required this.runs, this.style});
  final List<DocxRun> runs;
  final String? style;

  String get text => runs.map((r) => r.text).join();
}

class DocxTable {
  DocxTable({required this.rows});
  final List<List<String>> rows;
}

/// Lee un .docx (que es, en el fondo, un ZIP con XML adentro) usando
/// SOLO las librerías `archive` y `xml` -- mismo enfoque que ya probamos
/// funciona bien en la versión Python de este proyecto (docx_lite.py),
/// sin depender de ninguna librería de "lectura de Word" de terceros.
class DocxReaderService {
  static Future<List<Object>> read(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes, verify: false);

    final documentEntry = archive.files.firstWhere(
      (f) => f.name == 'word/document.xml',
      orElse: () => throw Exception('El documento no tiene la estructura esperada de un DOCX.'),
    );

    final xmlString = String.fromCharCodes(documentEntry.content as List<int>);
    final document = XmlDocument.parse(xmlString);

    final bodies = document.findAllElements('body', namespace: _wNs);
    if (bodies.isEmpty) return [];
    final body = bodies.first;

    final items = <Object>[];
    for (final child in body.childElements) {
      if (child.name.local == 'p') {
        items.add(_parseParagraph(child));
      } else if (child.name.local == 'tbl') {
        items.add(_parseTable(child));
      }
    }
    return items;
  }

  static DocxParagraph _parseParagraph(XmlElement pElement) {
    String? style;
    final pPr = pElement.getElement('pPr', namespace: _wNs);
    if (pPr != null) {
      final pStyle = pPr.getElement('pStyle', namespace: _wNs);
      style = pStyle?.getAttribute('val', namespace: _wNs);
    }

    final runs = <DocxRun>[];
    for (final rElement in pElement.findElements('r', namespace: _wNs)) {
      final textParts = rElement.findElements('t', namespace: _wNs).map((t) => t.innerText);
      var text = textParts.join();

      if (text.isEmpty) {
        if (rElement.getElement('tab', namespace: _wNs) != null) {
          text = '\t';
        } else if (rElement.getElement('br', namespace: _wNs) != null) {
          text = '\n';
        }
      }

      final rPr = rElement.getElement('rPr', namespace: _wNs);
      final bold = rPr?.getElement('b', namespace: _wNs) != null;
      final italic = rPr?.getElement('i', namespace: _wNs) != null;

      runs.add(DocxRun(text: text, bold: bold, italic: italic));
    }

    return DocxParagraph(runs: runs, style: _styleName(style));
  }

  static String? _styleName(String? styleId) {
    if (styleId == null) return null;
    const mapping = {
      'Heading1': 'Heading 1',
      'Heading2': 'Heading 2',
      'Heading3': 'Heading 3',
      'ListBullet': 'List Bullet',
    };
    return mapping[styleId] ?? styleId;
  }

  static DocxTable _parseTable(XmlElement tblElement) {
    final rows = <List<String>>[];
    for (final tr in tblElement.findElements('tr', namespace: _wNs)) {
      final cells = <String>[];
      for (final tc in tr.findElements('tc', namespace: _wNs)) {
        final texts = tc.findAllElements('t', namespace: _wNs).map((t) => t.innerText);
        cells.add(texts.join());
      }
      rows.add(cells);
    }
    return DocxTable(rows: rows);
  }
}
