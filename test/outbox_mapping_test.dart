import 'package:flutter_test/flutter_test.dart';
import 'package:plant_disease_detector/core/sync/outbox_processor.dart';

void main() {
  const user = '51cb214a-0482-49f1-9a51-8e919d0c9e42';
  const scanId = '0b6f3c1e-9a2d-4c7b-8e5f-1a2b3c4d5e6f';

  group('scanRowFromPayload', () {
    test('maps the current payload to scans columns', () {
      final row = OutboxProcessor.scanRowFromPayload({
        'id': scanId,
        'disease_name': 'Tomato Late Blight',
        'confidence_score': 0.93,
        'image_url': '/data/user/0/app/scans/$scanId.jpg',
        'crop_type': 'Tomato',
        'severity': 'high',
        'treatable': true,
        'scanned_at': '2026-10-09T08:00:00.000',
        'symptoms': ['Dark water-soaked patches'],
      }, userId: user, clientUuid: 'ignored');

      expect(row['id'], scanId);
      expect(row['user_id'], user);
      expect(row['disease_name'], 'Tomato Late Blight');
      expect(row['confidence_score'], 0.93);
      expect(row['crop_type'], 'Tomato');
      expect(row['severity'], 'high');
      expect(row['treatable'], true);
      expect(row['symptoms'], ['Dark water-soaked patches']);
    });

    test('accepts key names queued by older builds', () {
      final row = OutboxProcessor.scanRowFromPayload({
        'disease': 'Potato Early Blight',
        'confidence': 0.81,
        'image': 'assets/images/scan_spot.jpg',
      }, userId: user, clientUuid: scanId);

      expect(row['disease_name'], 'Potato Early Blight');
      expect(row['confidence_score'], 0.81);
      expect(row['image_url'], 'assets/images/scan_spot.jpg');
      expect(row['id'], scanId, reason: 'falls back to the outbox client UUID');
    });

    test('fills safe defaults and drops empty columns', () {
      final row = OutboxProcessor.scanRowFromPayload({}, userId: user, clientUuid: scanId);

      expect(row['disease_name'], 'Unknown');
      expect(row['crop_type'], 'Unknown');
      expect(row['severity'], 'medium');
      expect(row['treatable'], false);
      expect(row.containsKey('latin_name'), isFalse);
      expect(row.containsKey('image_url'), isFalse);
      expect(DateTime.tryParse(row['scanned_at'] as String), isNotNull);
    });

    test('leaves out ids that are not UUIDs so the database makes one', () {
      final row = OutboxProcessor.scanRowFromPayload({'id': 'scan_1712345'}, userId: user, clientUuid: 'also-not-a-uuid');
      expect(row.containsKey('id'), isFalse);
    });
  });
}
