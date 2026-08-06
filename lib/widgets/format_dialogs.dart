import 'package:flutter/material.dart';

/// Diálogos de formato incompatible / error, con el texto exacto pedido
/// en la especificación -- nunca una excepción técnica cruda.
class FormatDialogs {
  static Future<void> showIncompatible(BuildContext context, String specificMessage) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Formato no compatible'),
        content: Text(specificMessage),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  static Future<void> showError(BuildContext context, {required String title, required String message}) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
