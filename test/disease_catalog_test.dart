import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/disease_catalog.dart';
import 'package:plant_disease_detector/features/diagnosis/domain/disease_catalog_l10n.dart';

void main() {
  // The labels the TFLite model outputs, in class-index order.
  final labels = File('assets/models/labels.txt')
      .readAsLinesSync()
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  test('model has 38 classes and the catalog covers every one', () {
    expect(labels, hasLength(38));
    expect(DiseaseCatalog.all, hasLength(38));
    for (final label in labels) {
      expect(DiseaseCatalog.lookup(label), isNotNull, reason: 'no catalog entry for "$label"');
    }
  });

  test('every entry has symptoms and treatment steps', () {
    for (final d in DiseaseCatalog.all) {
      expect(d.symptoms, isNotEmpty, reason: d.label);
      expect(d.treatments, isNotEmpty, reason: d.label);
      expect(['none', 'low', 'medium', 'high'], contains(d.severity), reason: d.label);
      expect(d.isHealthy, d.severity == 'none', reason: d.label);
    }
  });

  test('every name, symptom and step has Sinhala and Tamil text', () {
    for (final d in DiseaseCatalog.all) {
      expect(DiseaseCatalog.localizedName(d.label, 'si'), isNot(d.label), reason: 'si name: ${d.label}');
      expect(DiseaseCatalog.localizedName(d.label, 'ta'), isNot(d.label), reason: 'ta name: ${d.label}');
      final texts = [...d.symptoms, for (final s in d.treatments) ...[s.title, s.desc]];
      for (final t in texts) {
        final tr = diseaseCatalogText[t];
        expect(tr, isNotNull, reason: 'missing translation: "$t"');
        expect(tr!.every((x) => x.trim().isNotEmpty), isTrue, reason: 'empty translation: "$t"');
      }
    }
  });
}
