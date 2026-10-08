import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../database/app_database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class OutboxProcessor {
  final AppDatabase db;
  bool _isProcessing = false;

  OutboxProcessor(this.db);

  /// Called when network connectivity is restored or periodically.
  Future<void> processOutbox() async {
    if (_isProcessing) return;
    
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.isEmpty || connectivityResult.contains(ConnectivityResult.none)) {
      return; // No network, skip processing
    }

    _isProcessing = true;
    try {
      // Get all pending or failed items that haven't exceeded retry limits
      final pendingItems = await (db.select(db.outbox)
            // 'processing' too: an item can be left in it if the app was closed mid-upload.
            ..where((t) => t.status.isIn(['pending', 'failed', 'processing']))
            ..where((t) => t.retryCount.isSmallerThanValue(5))
            ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.asc)]))
          .get();

      for (final item in pendingItems) {
        await _processSingleItem(item);
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _processSingleItem(OutboxData item) async {
    // Mark as processing
    await (db.update(db.outbox)..where((t) => t.id.equals(item.id))).write(
      OutboxCompanion(status: const Value('processing')),
    );

    try {
      // Example payload parsing
      final payload = jsonDecode(item.payload);
      
      bool success = false;
      if (item.type == 'diagnosis') {
        success = await _syncDiagnosis(item.clientUuid, payload);
      }

      if (success) {
        // Mark as synced or delete from outbox
        await (db.update(db.outbox)..where((t) => t.id.equals(item.id))).write(
          OutboxCompanion(status: const Value('synced')),
        );
      } else {
        // Increment retry count
        await _markAsFailed(item);
      }
    } catch (e) {
      await _markAsFailed(item);
    }
  }

  Future<void> _markAsFailed(OutboxData item) async {
    await (db.update(db.outbox)..where((t) => t.id.equals(item.id))).write(
      OutboxCompanion(
        status: const Value('failed'),
        retryCount: Value(item.retryCount + 1),
      ),
    );
  }

  static final _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

  /// Uploads the leaf photo to the private `leaf-images` bucket under the
  /// user's folder and returns a long-lived signed link to it. Returns '' when
  /// the file no longer exists (nothing to upload), null when the upload failed.
  Future<String?> _uploadLeafImage(SupabaseClient supabase, String userId, String scanId, String localPath) async {
    try {
      final file = XFile(localPath);
      final Uint8List bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (e) {
        debugPrint('Scan photo missing, uploading scan without it: $e');
        return ''; // photo was deleted from the phone; keep the scan without it
      }
      final objectPath = '$userId/$scanId.jpg';
      await supabase.storage.from('leaf-images').uploadBinary(
            objectPath,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      return await supabase.storage.from('leaf-images').createSignedUrl(objectPath, 60 * 60 * 24 * 365 * 5);
    } catch (e) {
      debugPrint('Leaf image upload failed: $e');
      return null;
    }
  }

  /// Uploads one queued scan as a row of the Supabase `scans` table.
  Future<bool> _syncDiagnosis(String clientUuid, Map<String, dynamic> payload) async {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false; // Not signed in yet; keep it queued.

    // Rows queued by older builds used other key names; map them across.
    final row = <String, dynamic>{
      'disease_name': payload['disease_name'] ?? payload['disease'] ?? 'Unknown',
      'confidence_score': payload['confidence_score'] ?? payload['confidence'] ?? 0.0,
      'image_url': payload['image_url'] ?? payload['image'],
      'crop_type': payload['crop_type'] ?? 'Unknown',
      'severity': payload['severity'] ?? 'medium',
      'latin_name': payload['latin_name'],
      'field_location': payload['field_location'],
      'treatable': payload['treatable'] ?? false,
      'scanned_at': payload['scanned_at'] ?? DateTime.now().toIso8601String(),
      'symptoms': payload['symptoms'],
      'user_id': payload['user_id'] ?? userId,
    }..removeWhere((_, v) => v == null);
    final id = (payload['id'] ?? clientUuid).toString();
    if (_uuid.hasMatch(id)) row['id'] = id;

    // The photo is still a file on this phone: upload it so officers and the
    // farmer's other devices can see it. Retry later if the upload fails.
    final localImage = row['image_url'] as String?;
    if (localImage != null && localImage.isNotEmpty && !localImage.startsWith('http') && !localImage.startsWith('assets/')) {
      final url = await _uploadLeafImage(supabase, userId, id, localImage);
      if (url == null) return false;
      if (url.isEmpty) {
        row.remove('image_url');
      } else {
        row['image_url'] = url;
      }
    }

    try {
      await supabase.from('scans').insert(row);
      return true;
    } on PostgrestException catch (e) {
      // 23505 = already uploaded (e.g. the app closed before marking it synced).
      if (e.code == '23505') return true;
      debugPrint('Scan sync failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Scan sync failed: $e');
      return false; // Will retry later
    }
  }
}
