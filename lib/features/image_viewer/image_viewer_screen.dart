import 'dart:io';

import 'package:flutter/material.dart';

/// Vista completa de una fotografía con zoom y desplazamiento
/// (InteractiveViewer es parte del propio Flutter, sin dependencia
/// nueva).
class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.file(File(path)),
        ),
      ),
    );
  }
}
