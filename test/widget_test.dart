import 'package:flutter_test/flutter_test.dart';

import 'package:docconvert_ncts/app.dart';

void main() {
  testWidgets('La app abre sin lanzar excepciones', (tester) async {
    await tester.pumpWidget(const DocConvertApp());
    // No se usa pumpAndSettle: el provider de "Archivos creados" carga
    // desde disco vía path_provider, que no tiene canal de plataforma
    // disponible en el entorno de pruebas de Flutter (ni en local ni en
    // CI) -- esa carga asíncrona nunca "se asienta" ahí, así que
    // pumpAndSettle se queda esperando para siempre. Un solo pump()
    // alcanza para confirmar que el árbol de widgets se construye sin
    // lanzar excepciones en el primer frame, que es lo que esta prueba
    // necesita verificar.
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
