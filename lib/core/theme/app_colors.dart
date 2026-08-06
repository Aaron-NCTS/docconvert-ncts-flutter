import 'package:flutter/material.dart';

/// Paleta de colores propia de DocConvert NCTS.
///
/// Identidad: azul marino institucional + acento dorado (consistente con
/// la identidad de NCTS usada en otros documentos de la organización),
/// deliberadamente distinta de la paleta naranja/roja típica de apps de
/// escaneo comerciales como CamScanner.
class AppColors {
  AppColors._();

  // Color "semilla" para generar el ColorScheme de Material 3.
  static const Color seed = Color(0xFF14213D); // azul marino profundo

  static const Color accentGold = Color(0xFFC9A227);

  // Colores de estado, iguales en modo claro y oscuro (para que el
  // significado no cambie, solo el fondo detrás de ellos).
  static const Color success = Color(0xFF2E7D5B);
  static const Color warning = Color(0xFFB8860B);
  static const Color error = Color(0xFFC0392B);
}
