import 'package:flutter_test/flutter_test.dart';

import 'package:docconvert_ncts/app.dart';

void main() {
  testWidgets('La app abre y muestra el título en Inicio', (tester) async {
    await tester.pumpWidget(const DocConvertApp());

    expect(find.text('DocConvert NCTS'), findsOneWidget);
    expect(find.text('Inicio'), findsOneWidget);
  });
}
