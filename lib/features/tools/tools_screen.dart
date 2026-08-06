import 'package:flutter/material.dart';

/// Pantalla "Herramientas": las 3 tarjetas de conversión. En esta Fase 1
/// solo navegan a pantallas placeholder -- la funcionalidad real de cada
/// una llega en su fase correspondiente (Fotos a PDF en la Fase 3, Word a
/// PDF en la Fase 4, PDF a Word en la Fase 5).
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Herramientas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToolCard(
            icon: Icons.photo_library_outlined,
            title: 'Fotos a PDF',
            subtitle: 'Convierte una o varias fotografías en un PDF',
            onTap: () => _showPending(context, 'Fotos a PDF'),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.picture_as_pdf_outlined,
            title: 'Word a PDF',
            subtitle: 'Convierte un documento DOCX en PDF',
            onTap: () => _showPending(context, 'Word a PDF'),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.description_outlined,
            title: 'PDF a Word',
            subtitle: 'Convierte un documento PDF en DOCX',
            onTap: () => _showPending(context, 'PDF a Word'),
          ),
        ],
      ),
    );
  }

  void _showPending(BuildContext context, String tool) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$tool se implementa en una fase próxima.')),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
