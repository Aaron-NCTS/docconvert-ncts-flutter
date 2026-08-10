import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Necesario antes de usar DateFormat con configuración regional
  // ("d MMM yyyy" en español) en las tarjetas de archivos -- sin esto,
  // la app truena en tiempo de ejecución con LocaleDataException.
  await initializeDateFormatting('es_MX');
  runApp(const DocConvertApp());
}
