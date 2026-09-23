// Basic smoke test for Lumina app.

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_disease_detector/main.dart';

void main() {
  testWidgets('App launches and shows splash screen',
      (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CropGuardApp());
    // Splash screen should be visible initially
    expect(find.text('Lumina – Crop Disease Detector'), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
  });
}
