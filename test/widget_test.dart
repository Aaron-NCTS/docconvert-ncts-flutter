import 'package:flutter_test/flutter_test.dart';

import 'package:docconvert_ncts/app.dart';

void main() {
  testWidgets('La app abre sin lanzar excepciones', (tester) async {
    await tester.pumpWidget(const DocConvertApp());
    // El provider de "Archivos creados" carga de forma asíncrona
    // (lee el índice JSON del disco); pumpAndSettle espera a que esa
    // carga termine antes de revisar la interfaz, en vez de revisar
    // el primer frame (que todavía muestra el estado "cargando").
    await tester.pumpAndSettle();

    expect(find.text('DocConvert NCTS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
