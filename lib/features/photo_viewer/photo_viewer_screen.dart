import 'dart:io';

import 'package:flutter/material.dart';

/// Vista completa de una fotografía dentro de la app: zoom y
/// desplazamiento con InteractiveViewer (parte del SDK de Flutter, sin
/// ninguna dependencia adicional), y botón de regresar.
class PhotoViewerScreen extends StatelessWidget {
  const PhotoViewerScreen({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4,
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}
