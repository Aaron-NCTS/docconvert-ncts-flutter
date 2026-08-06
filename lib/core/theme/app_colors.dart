import 'package:flutter/material.dart';

/// Paleta de colores propia de DocConvert NCTS.
///
/// Identidad: tomada directamente del logotipo real de NovaCore Tech
/// Solutions (morado/violeta neón sobre fondo oscuro, estética
/// tecnológica) -- no es una elección genérica, es la marca real de la
/// empresa. El modo oscuro es el que más fielmente representa esa
/// identidad; el modo claro usa el mismo violeta como acento sobre un
/// fondo neutro, para mantener coherencia sin perder legibilidad.
class AppColors {
  AppColors._();

  /// Color "semilla" para generar el ColorScheme de Material 3 -- un
  /// violeta rico que corresponde al tono del logotipo.
  static const Color seed = Color(0xFF8B5CF6);

  /// Tono más saturado del logotipo, para acentos puntuales (no como
  /// color base de todo el ColorScheme, que ya genera Material 3 a
  /// partir de `seed`).
  static const Color neonAccent = Color(0xFFB026FF);

  static const Color darkBackground = Color(0xFF0B0B12);
  static const Color darkSurface = Color(0xFF15141F);

  // Colores de estado, iguales en modo claro y oscuro (para que el
  // significado no cambie, solo el fondo detrás de ellos).
  static const Color success = Color(0xFF2FBF71);
  static const Color warning = Color(0xFFE0A72E);
  static const Color error = Color(0xFFE5484D);
}
