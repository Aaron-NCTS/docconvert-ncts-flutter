import 'package:flutter/material.dart';

/// Placeholder de la pantalla de escaneo. La cámara real, detección de
/// bordes, ajuste manual de esquinas y filtros se implementan en la
/// Fase 6 -- deliberadamente no simulados aquí, para no dar la impresión
/// de una función terminada cuando no lo está.
class ScannerScreen extends StatelessWidget {
  const ScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              Text(
                'El escáner con cámara se implementa en una fase próxima.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
