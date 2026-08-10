import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

/// Visor de PDF DENTRO de la app -- scroll, zoom y todas las páginas,
/// sin salir de DocConvert NCTS. Si el PDF no se puede abrir (dañado,
/// protegido), Syncfusion dispara `onDocumentLoadFailed`, que aquí se
/// traduce a un mensaje entendible en vez de una pantalla en blanco.
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, overflow: TextOverflow.ellipsis)),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : SfPdfViewer.file(
              File(widget.path),
              onDocumentLoadFailed: (details) {
                setState(() {
                  _error = 'No se pudo abrir el documento. Puede estar dañado o protegido con contraseña.';
                });
              },
            ),
    );
  }
}
