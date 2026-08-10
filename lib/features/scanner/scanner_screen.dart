import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../widgets/format_dialogs.dart';
import 'scan_crop_screen.dart';
import 'scan_pages_screen.dart';

/// Escáner: captura real con la cámara del dispositivo.
///
/// El permiso de cámara se pide solo al llegar aquí (no al abrir la
/// app), y si se niega, la app sigue funcionando normalmente -- solo
/// esta pantalla explica que hace falta el permiso, sin bloquear nada
/// más (Fotos a PDF, Word a PDF, PDF a Word siguen disponibles).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, this.returnPathOnly = false});

  /// Cuando es true (usado por "Agregar página" desde ScanPagesScreen),
  /// al capturar y recortar la foto regresa esa ruta directamente con
  /// Navigator.pop, en vez de navegar a una NUEVA ScanPagesScreen (lo
  /// cual anidaría la pantalla dentro de sí misma).
  final bool returnPathOnly;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  CameraController? _controller;
  bool _permissionDenied = false;
  bool _initializing = false;
  String? _errorMessage;

  Future<void> _startCamera() async {
    setState(() {
      _initializing = true;
      _errorMessage = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _errorMessage = 'No se encontró ninguna cámara en este dispositivo.';
        });
        return;
      }
      final controller = CameraController(cameras.first, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      final isPermission = e.toString().toLowerCase().contains('permission');
      setState(() {
        _initializing = false;
        _permissionDenied = isPermission;
        _errorMessage = isPermission ? null : 'No se pudo iniciar la cámara.';
      });
    }
  }

  Future<void> _requestPermissionAndStart() async {
    final proceed = await FormatDialogs.confirm(
      context,
      title: 'Permiso de cámara',
      message: 'Se necesita acceso a la cámara para escanear documentos.',
      confirmLabel: 'Permitir',
    );
    if (!proceed) return;
    await _startCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    try {
      final photo = await controller.takePicture();
      if (!mounted) return;

      // El recorte es opcional (el usuario puede pulsar "Omitir"); si lo
      // omite, se usa la foto completa tal cual.
      final croppedPath = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => ScanCropScreen(imagePath: photo.path)),
      );
      if (croppedPath == null || !mounted) return;

      if (widget.returnPathOnly) {
        Navigator.of(context).pop(croppedPath);
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ScanPagesScreen(firstPagePath: croppedPath)),
      );
    } catch (e) {
      if (!mounted) return;
      await FormatDialogs.showError(context, title: 'No se pudo capturar la foto', message: 'Intenta de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    if (controller != null && controller.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(child: CameraPreview(controller)),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => setState(() => _controller = null),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.white70, width: 4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Escanear')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.document_scanner_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                Text(_errorMessage!, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
              ] else if (_permissionDenied) ...[
                Text(
                  'Se necesita acceso a la cámara para escanear documentos.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: _initializing ? null : _requestPermissionAndStart,
                icon: _initializing
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.camera_alt_outlined),
                label: Text(_initializing ? 'Abriendo cámara...' : 'Abrir cámara'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
