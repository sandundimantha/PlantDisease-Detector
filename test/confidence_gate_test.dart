import 'package:flutter_test/flutter_test.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/confidence_gate.dart';

void main() {
  group('ConfidenceGate', () {
    test('70% and above shows the result', () {
      expect(ConfidenceGate.evaluate(0.70), ConfidenceResult.show);
      expect(ConfidenceGate.evaluate(0.982), ConfidenceResult.show);
      expect(ConfidenceGate.evaluate(1.0), ConfidenceResult.show);
    });

    test('40% to under 70% flags the result as uncertain', () {
      expect(ConfidenceGate.evaluate(0.40), ConfidenceResult.flag);
      expect(ConfidenceGate.evaluate(0.55), ConfidenceResult.flag);
      expect(ConfidenceGate.evaluate(0.6999), ConfidenceResult.flag);
    });

    test('under 40% escalates to an officer', () {
      expect(ConfidenceGate.evaluate(0.3999), ConfidenceResult.escalate);
      expect(ConfidenceGate.evaluate(0.0), ConfidenceResult.escalate);
    });
  });
}
