import 'dart:io';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'docx_reader_service.dart';

/// Convierte un DOCX ya validado a PDF.
///
/// Limitación honesta (la misma que ya teníamos documentada en la
/// versión Python): conserva párrafos, encabezados, negritas/cursivas,
/// listas con viñetas y tablas simples -- no reproduce imágenes,
/// encabezados/pies de página, columnas múltiples, ni estilos de tabla
/// avanzados del documento original.
class WordToPdfService {
  static Future<void> convert({
    required File input,
    required String outputPath,
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Leyendo documento Word...');
    final items = await DocxReaderService.read(input);

    if (items.isEmpty) {
      throw Exception('El documento Word está vacío o no se pudo leer su contenido.');
    }

    onProgress?.call('Generando PDF...');
    final doc = pw.Document();

    final content = <pw.Widget>[];
    for (final item in items) {
      if (item is DocxParagraph) {
        content.add(_buildParagraph(item));
      } else if (item is DocxTable) {
        content.add(_buildTable(item));
      }
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(48),
        build: (context) => content,
      ),
    );

    onProgress?.call('Guardando PDF...');
    await File(outputPath).writeAsBytes(await doc.save());
  }

  static pw.Widget _buildParagraph(DocxParagraph paragraph) {
    final text = paragraph.text.trim();
    if (text.isEmpty) {
      return pw.SizedBox(height: 8);
    }

    const headingSizes = {'Heading 1': 20.0, 'Heading 2': 16.0, 'Heading 3': 13.0};
    final headingSize = headingSizes[paragraph.style];

    if (headingSize != null) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: headingSize, fontWeight: pw.FontWeight.bold),
        ),
      );
    }

    if (paragraph.style == 'List Bullet') {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(left: 14, bottom: 4),
        child: pw.Text('•  $text', style: const pw.TextStyle(fontSize: 11)),
      );
    }

    // Runs con negrita/cursiva dentro del mismo párrafo.
    final spans = <pw.TextSpan>[];
    for (final run in paragraph.runs) {
      if (run.text.isEmpty) continue;
      spans.add(
        pw.TextSpan(
          text: run.text,
          style: pw.TextStyle(
            fontWeight: run.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontStyle: run.italic ? pw.FontStyle.italic : pw.FontStyle.normal,
          ),
        ),
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: spans.isEmpty ? [pw.TextSpan(text: text)] : spans,
          style: const pw.TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  static pw.Widget _buildTable(DocxTable table) {
    if (table.rows.isEmpty) return pw.SizedBox();

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.TableHelper.fromTextArray(
        data: table.rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
        headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
        cellStyle: const pw.TextStyle(fontSize: 9),
        cellAlignment: pw.Alignment.centerLeft,
        cellPadding: const pw.EdgeInsets.all(6),
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      ),
    );
  }
}
