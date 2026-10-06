import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/features/home/data/saved_item.dart';
import 'package:plant_disease_detector/models/disease_result.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SavedItemsNotifier — CRUD for the signed-in user's `saved_items` rows.
// Create: saveScan · Read: build · Update: updateNote · Delete: remove
// RLS on the table limits every query to the caller's own rows.
// ─────────────────────────────────────────────────────────────────────────────
class SavedItemsNotifier extends AsyncNotifier<List<SavedItem>> {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<SavedItem>> build() async {
    final fetchedFor = _client.auth.currentUser?.id;
    // Refetch when a different account signs in (or the user signs out), so one
    // user's bookmarks are never shown to the next user on the same device.
    final sub = _client.auth.onAuthStateChange.listen((authState) {
      if (authState.session?.user.id != fetchedFor) ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

    if (fetchedFor == null) return [];
    final rows = await _client
        .from('saved_items')
        .select()
        .order('created_at', ascending: false);
    return (rows as List).map((row) => SavedItem.fromJson(row)).toList();
  }

  List<SavedItem> get _items => state.valueOrNull ?? const [];

  SavedItem? itemForScan(String scanId) {
    for (final item in _items) {
      if (item.scanId == scanId) return item;
    }
    return null;
  }

  Future<void> saveScan(ScanRecord scan) async {
    final confidence = (scan.confidenceScore * 100).round();
    final crop = scan.cropType.isNotEmpty ? scan.cropType : 'Crop';
    final row = await _client
        .from('saved_items')
        .insert({
          'scan_id': scan.id,
          'title': scan.diseaseName,
          'subtitle': '$crop • $confidence% confidence',
        })
        .select()
        .single();
    state = AsyncValue.data([SavedItem.fromJson(row), ..._items]);
  }

  Future<void> updateNote(String id, String note) async {
    final trimmed = note.trim();
    final row = await _client
        .from('saved_items')
        .update({'note': trimmed.isEmpty ? null : trimmed})
        .eq('id', id)
        .select()
        .single();
    final updated = SavedItem.fromJson(row);
    state = AsyncValue.data([
      for (final item in _items) item.id == id ? updated : item,
    ]);
  }

  Future<void> remove(String id) async {
    await _client.from('saved_items').delete().eq('id', id);
    state = AsyncValue.data(_items.where((item) => item.id != id).toList());
  }

  // Undo for remove: puts the same row (same id and date) back.
  Future<void> restore(SavedItem item) async {
    final row = await _client
        .from('saved_items')
        .insert(item.toRestoreJson())
        .select()
        .single();
    final restored = [SavedItem.fromJson(row), ..._items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = AsyncValue.data(restored);
  }
}

final savedItemsProvider =
    AsyncNotifierProvider<SavedItemsNotifier, List<SavedItem>>(
  SavedItemsNotifier.new,
);
