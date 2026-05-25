import 'package:flutter_test/flutter_test.dart';
import 'package:vitamin_d_sensor/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We use VitaminDApp which is the main entry point defined in lib/app.dart
    await tester.pumpWidget(const VitaminDApp());

    // Verify that the app widget is present.
    expect(find.byType(VitaminDApp), findsOneWidget);
  });
}
