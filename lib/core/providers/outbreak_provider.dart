import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:plant_disease_detector/models/outbreak_report.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/core/providers/location_provider.dart';

final outbreakProvider = FutureProvider<List<OutbreakReport>>((ref) async {
  final client = Supabase.instance.client;
  final pos = ref.watch(locationProvider.select((s) => s.position));
  final response = await client.from('outbreak_reports').select().order('created_at', ascending: false);
  return (response as List)
      .map((row) => OutbreakReport.fromJson(row, fromLat: pos?.latitude, fromLng: pos?.longitude))
      .toList();
});

class OutbreakService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createOutbreak(Map<String, dynamic> data) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    data['reported_by'] = user.id;
    await _client.from('outbreak_reports').insert(data);
  }

  Future<void> updateOutbreak(String id, Map<String, dynamic> updates) async {
    await _client.from('outbreak_reports').update(updates).eq('id', id);
  }

  Future<void> deleteOutbreak(String id) async {
    await _client.from('outbreak_reports').delete().eq('id', id);
  }
}
