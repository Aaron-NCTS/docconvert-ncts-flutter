import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/document_item.dart';

/// Tarjeta compacta para un archivo ya creado, con menú de tres puntos
/// (Abrir, Compartir, Renombrar, Información, Eliminar) -- pediste
/// explícitamente que no fuera una tarjeta gigante con botones sueltos.
class DocumentCard extends StatelessWidget {
  const DocumentCard({
    super.key,
    required this.item,
    required this.onOpen,
    required this.onShare,
    required this.onRename,
    required this.onDelete,
    required this.onInfo,
  });

  final DocumentItem item;
  final VoidCallback onOpen;
  final VoidCallback onShare;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onInfo;

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;

    if (isToday) return 'Hoy';
    if (isYesterday) return 'Ayer';
    return DateFormat('d MMM yyyy', 'es_MX').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPdf = item.isPdf;

    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isPdf ? colorScheme.primaryContainer : colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPdf ? Icons.picture_as_pdf_outlined : Icons.description_outlined,
                  size: 20,
                  color: isPdf ? colorScheme.onPrimaryContainer : colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.extension.toUpperCase()} · ${_formatSize(item.sizeBytes)} · ${_formatDate(item.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'open':
                      onOpen();
                    case 'share':
                      onShare();
                    case 'rename':
                      onRename();
                    case 'info':
                      onInfo();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'open', child: Text('Abrir')),
                  PopupMenuItem(value: 'share', child: Text('Compartir')),
                  PopupMenuItem(value: 'rename', child: Text('Renombrar')),
                  PopupMenuItem(value: 'info', child: Text('Información')),
                  PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
