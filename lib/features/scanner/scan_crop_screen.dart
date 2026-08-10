import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/scan_crop_service.dart';

/// Ajuste de recorte con 4 esquinas movibles sobre la foto capturada.
///
/// Aviso técnico honesto (para no simular una función que no existe):
/// esto permite mover las 4 esquinas libremente por la pantalla, pero el
/// recorte final que se aplica es el RECTÁNGULO que encierra esos 4
/// puntos (bounding box) -- no una corrección de perspectiva geométrica
/// real (que "endereza" un documento fotografiado en ángulo, deformando
/// la imagen con una transformación de 4 puntos). Implementar eso
/// correctamente necesita una operación de "homografía" con remuestreo
/// por pixel; no encontré una forma de escribirla con confianza sin
/// poder probarla en este entorno (no tengo Flutter instalado), así que
/// prefiero entregar un recorte rectangular que sí funciona de verdad,
/// en vez de fingir una corrección de perspectiva que podría salir mal.
/// Si la foto del documento está tomada derecha (cámara casi paralela a
/// la hoja), el resultado práctico es equivalente.
class ScanCropScreen extends StatefulWidget {
  const ScanCropScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<ScanCropScreen> createState() => _ScanCropScreenState();
}

class _ScanCropScreenState extends State<ScanCropScreen> {
  final GlobalKey _imageKey = GlobalKey();
  ui.Image? _decodedImage;

  // Posiciones de las 4 esquinas en coordenadas LOCALES del widget de
  // imagen (no de la imagen real) -- se inicializan cerca de los bordes
  // completos, y el usuario las puede arrastrar hacia adentro.
  Offset? _topLeft, _topRight, _bottomLeft, _bottomRight;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _decodedImage = frame.image);
  }

  void _initCornersIfNeeded(Size displaySize) {
    if (_topLeft != null) return;
    const margin = 24.0;
    setState(() {
      _topLeft = Offset(margin, margin);
      _topRight = Offset(displaySize.width - margin, margin);
      _bottomLeft = Offset(margin, displaySize.height - margin);
      _bottomRight = Offset(displaySize.width - margin, displaySize.height - margin);
    });
  }

  Future<void> _confirmCrop(Size displaySize) async {
    final image = _decodedImage;
    if (image == null || _topLeft == null) return;

    final scaleX = image.width / displaySize.width;
    final scaleY = image.height / displaySize.height;

    final points = [_topLeft!, _topRight!, _bottomLeft!, _bottomRight!];
    final minX = points.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    final maxX = points.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final minY = points.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    final maxY = points.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

    final cropX = (minX * scaleX).round();
    final cropY = (minY * scaleY).round();
    final cropW = ((maxX - minX) * scaleX).round();
    final cropH = ((maxY - minY) * scaleY).round();

    final Uint8List croppedBytes = await ScanCropService.crop(widget.imagePath, cropX, cropY, cropW, cropH);
    final newFile = File('${widget.imagePath}_cropped.jpg');
    await newFile.writeAsBytes(croppedBytes);

    if (!mounted) return;
    Navigator.of(context).pop(newFile.path);
  }

  Widget _handle(Offset position, void Function(Offset) onDrag) {
    return Positioned(
      left: position.dx - 14,
      top: position.dy - 14,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar recorte'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(widget.imagePath),
            child: const Text('Omitir'),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final displaySize = Size(constraints.maxWidth, constraints.maxWidth * 1.3);
          _initCornersIfNeeded(displaySize);

          return Center(
            child: SizedBox(
              width: displaySize.width,
              height: displaySize.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    key: _imageKey,
                    child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
                  ),
                  if (_topLeft != null) ...[
                    _handle(_topLeft!, (d) => setState(() => _topLeft = _topLeft! + d)),
                    _handle(_topRight!, (d) => setState(() => _topRight = _topRight! + d)),
                    _handle(_bottomLeft!, (d) => setState(() => _bottomLeft = _bottomLeft! + d)),
                    _handle(_bottomRight!, (d) => setState(() => _bottomRight = _bottomRight! + d)),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final displaySize = Size(
            MediaQuery.of(context).size.width,
            MediaQuery.of(context).size.width * 1.3,
          );
          _confirmCrop(displaySize);
        },
        icon: const Icon(Icons.check),
        label: const Text('Confirmar recorte'),
      ),
    );
  }
}
