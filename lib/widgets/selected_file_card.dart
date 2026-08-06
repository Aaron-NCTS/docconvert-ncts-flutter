import 'package:flutter/material.dart';

/// Tarjeta compacta para un archivo ya seleccionado (PDF o DOCX): nombre,
/// tamaño, estado, y botón para quitarlo. Reutilizada por Word a PDF y
/// PDF a Word.
class SelectedFileCard extends StatelessWidget {
  const SelectedFileCard({
    super.key,
    required this.fileName,
    required this.fileSizeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.onRemove,
    this.enabled = true,
  });

  final String fileName;
  final String fileSizeLabel;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onRemove;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.description_outlined, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$fileSizeLabel  ·  $statusLabel',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: statusColor),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: enabled ? onRemove : null,
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Quitar',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.4),
                foregroundColor: colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
