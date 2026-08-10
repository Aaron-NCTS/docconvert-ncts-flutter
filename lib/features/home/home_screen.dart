import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/documents_provider.dart';
import '../../services/document_opener_service.dart';
import '../../services/share_service.dart';
import '../../widgets/document_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/format_dialogs.dart';
import '../documents/documents_screen.dart';

/// Pantalla de Inicio: encabezado con el logotipo real de NovaCore,
/// accesos rápidos a Escanear y Fotos a PDF, y una vista previa real
/// (3-5 elementos) de "Archivos creados" con acceso a la lista completa.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Consumer<DocumentsProvider>(
        builder: (context, provider, _) {
          final preview = provider.items.take(5).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('DocConvert NCTS', style: Theme.of(context).textTheme.titleLarge),
                            Text(
                              'Convierte y administra tus documentos',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.document_scanner_outlined,
                          label: 'Escanear',
                          isPrimary: true,
                          onTap: () => onNavigateToTab?.call(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.photo_library_outlined,
                          label: 'Fotos a PDF',
                          isPrimary: false,
                          onTap: () => onNavigateToTab?.call(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('Archivos creados', style: Theme.of(context).textTheme.titleMedium),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DocumentsScreen()),
                        ),
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                ),
              ),
              if (provider.isLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (preview.isEmpty)
                const SliverPadding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.description_outlined,
                      title: 'Todavía no has creado documentos',
                      message: 'Escanea una página o convierte tu primer archivo\npara verlo aquí.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  sliver: SliverList.separated(
                    itemCount: preview.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = preview[index];
                      return DocumentCard(
                        item: item,
                        onOpen: () => DocumentOpenerService.open(context, item),
                        onShare: () => ShareService.shareFile(item.path),
                        onRename: () {}, // renombrar/eliminar/info completos viven en "Ver todos"
                        onDelete: () async {
                          final confirmed = await FormatDialogs.confirm(
                            context,
                            title: 'Eliminar archivo',
                            message: '¿Quieres eliminar este archivo de forma permanente?',
                            confirmLabel: 'Eliminar',
                          );
                          if (confirmed) {
                            await context.read<DocumentsProvider>().removeItem(item.id);
                          }
                        },
                        onInfo: () {},
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final background = isPrimary
        ? LinearGradient(
            colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final foregroundColor = isPrimary ? Colors.white : colorScheme.primary;
    final labelColor = isPrimary ? Colors.white : colorScheme.onSurface;

    return Material(
      color: isPrimary ? null : colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(18),
      elevation: isPrimary ? 4 : 0,
      shadowColor: isPrimary ? colorScheme.primary.withValues(alpha: 0.4) : null,
      child: Ink(
        decoration: BoxDecoration(gradient: background, borderRadius: BorderRadius.circular(18)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
            child: Column(
              children: [
                Icon(icon, color: foregroundColor, size: 26),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: labelColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
