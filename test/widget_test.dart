import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Layar awal tampil', (WidgetTester tester) async {
    await tester.pumpWidget(const WattpretApp());
    expect(find.text('Daftar dengan email'), findsOneWidget);
  });
}
