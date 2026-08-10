import 'package:uuid/uuid.dart';

enum ScanFilter { original, automatico, documento, blancoYNegro, escalaDeGrises, contrasteAlto }

/// Una página del documento que se está escaneando: ruta de la imagen
/// YA recortada (si el usuario ajustó el recorte) y el filtro aplicado.
class ScanPage {
  ScanPage({required this.processedPath, this.filter = ScanFilter.original}) : id = const Uuid().v4();

  final String id;
  String processedPath;
  ScanFilter filter;
}
