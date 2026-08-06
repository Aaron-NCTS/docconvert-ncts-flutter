import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// Pantalla de Inicio. En esta Fase 1 todavía no hay persistencia (eso es
/// Fase 2), así que "Documentos recientes" siempre muestra su estado
/// vacío -- pero la estructura visual ya queda lista para conectarse a
/// datos reales sin rehacer la pantalla.
///
/// `onNavigateToTab` permite que los accesos rápidos (Escanear, Fotos a
/// PDF) cambien de pestaña en la barra inferior, en vez de abrir una
/// pantalla nueva encima -- mantiene una sola pila de navegación.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onNavigateToTab});

  final ValueChanged<int>? onNavigateToTab;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [colorScheme.primary, colorScheme.tertiary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.description_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DocConvert NCTS',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
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
              child: Text(
                'Documentos recientes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.description_outlined,
              title: 'Todavía no has creado documentos',
              message: 'Escanea una página o convierte tu primer archivo\npara verlo aquí.',
            ),
          ),
        ],
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
        decoration: BoxDecoration(
          gradient: background,
          borderRadius: BorderRadius.circular(18),
        ),
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
