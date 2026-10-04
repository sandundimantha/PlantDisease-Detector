import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:plant_disease_detector/models/consultation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConsultationRepository — Supabase data layer for consultations
// ─────────────────────────────────────────────────────────────────────────────
class ConsultationRepository {
  final SupabaseClient _client;

  ConsultationRepository(this._client);

  // ── Fetch all consultations (for officer) ─────────────────────────────────
  Future<List<Consultation>> fetchAllConsultations({String? statusFilter}) async {
    try {
      var query = _client
          .from('consultations')
          .select('''
            *,
            farmer_profile:farmer_id(full_name, avatar_url),
            officer_profile:officer_id(full_name, avatar_url)
          ''')
          .order('created_at', ascending: false);

      if (statusFilter != null && statusFilter != 'all') {
        final data = await (_client.from('consultations').select('''
          *,
          farmer_profile:farmer_id(full_name, avatar_url),
          officer_profile:officer_id(full_name, avatar_url)
        ''').eq('status', statusFilter).order('created_at', ascending: false));
        return (data as List).map((e) => Consultation.fromJson(e)).toList();
      }

      final data = await query;
      return (data as List).map((e) => Consultation.fromJson(e)).toList();
    } catch (e) {
      debugPrint('ConsultationRepository.fetchAll error: $e');
      return [];
    }
  }

  // ── Fetch consultations for a specific farmer ─────────────────────────────
  Future<List<Consultation>> fetchFarmerConsultations(String farmerId) async {
    try {
      final data = await _client
          .from('consultations')
          .select('''
            *,
            farmer_profile:farmer_id(full_name, avatar_url),
            officer_profile:officer_id(full_name, avatar_url)
          ''')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);
      return (data as List).map((e) => Consultation.fromJson(e)).toList();
    } catch (e) {
      debugPrint('ConsultationRepository.fetchFarmer error: $e');
      return [];
    }
  }

  // ── Fetch a single consultation by ID ─────────────────────────────────────
  Future<Consultation?> fetchConsultationById(String id) async {
    try {
      final data = await _client
          .from('consultations')
          .select('''
            *,
            farmer_profile:farmer_id(full_name, avatar_url),
            officer_profile:officer_id(full_name, avatar_url)
          ''')
          .eq('id', id)
          .maybeSingle();
      if (data == null) return null;
      return Consultation.fromJson(data);
    } catch (e) {
      debugPrint('ConsultationRepository.fetchById error: $e');
      return null;
    }
  }

  // ── Create a new consultation ─────────────────────────────────────────────
  Future<Consultation?> createConsultation({
    required String farmerId,
    String? scanId,
    String? diseaseName,
    String? severity,
    String? imageUrl,
    String? location,
  }) async {
    try {
      final data = await _client.from('consultations').insert({
        'farmer_id': farmerId,
        'scan_id': scanId,
        'disease_name': diseaseName,
        'severity': severity ?? 'medium',
        'image_url': imageUrl,
        'location': location,
        'status': severity == 'high' ? 'pending' : 'pending',
      }).select().single();
      return Consultation.fromJson(data);
    } catch (e) {
      debugPrint('ConsultationRepository.create error: $e');
      return null;
    }
  }

  // ── Update consultation status ─────────────────────────────────────────────
  Future<void> updateStatus(String consultationId, String status) async {
    try {
      final updates = <String, dynamic>{'status': status};
      if (status == 'resolved') {
        updates['resolved_at'] = DateTime.now().toIso8601String();
      }
      await _client.from('consultations').update(updates).eq('id', consultationId);
    } catch (e) {
      debugPrint('ConsultationRepository.updateStatus error: $e');
    }
  }

  // ── Assign officer to consultation ────────────────────────────────────────
  // Throws so the UI can report failure. RLS blocks return 0 rows rather than
  // an error, so the affected rows are checked explicitly.
  Future<void> assignOfficer(String consultationId, String officerId) async {
    final rows = await _client.from('consultations').update({
      'officer_id': officerId,
      'status': 'open',
    }).eq('id', consultationId).select('id');
    if ((rows as List).isEmpty) {
      throw Exception('Case could not be accepted (no permission or already removed).');
    }
  }

  // ── Delete consultation ───────────────────────────────────────────────────
  Future<void> deleteConsultation(String consultationId) async {
    final rows = await _client
        .from('consultations')
        .delete()
        .eq('id', consultationId)
        .select('id');
    if ((rows as List).isEmpty) {
      throw Exception('Case could not be deleted (no permission or already removed).');
    }
  }

  // ── Dashboard stats for officer ──────────────────────────────────────────
  Future<Map<String, int>> fetchOfficerStats() async {
    try {
      final all = await _client.from('consultations').select('status, severity');
      final list = all as List;
      
      final pending = list.where((c) => c['status'] == 'pending' || c['status'] == 'open').length;
      
      final today = DateTime.now();
      final resolvedToday = list.where((c) {
        if (c['status'] != 'resolved') return false;
        // We don't have resolved_at in this query, use created_at as approximation
        return true; // Will refine later
      }).length;
      
      // Fetch resolved today specifically
      final resolvedTodayData = await _client
          .from('consultations')
          .select('id')
          .eq('status', 'resolved')
          .gte('resolved_at', DateTime(today.year, today.month, today.day).toIso8601String());
      
      final urgent = list.where((c) => c['severity'] == 'high' && c['status'] != 'resolved').length;

      return {
        'pending': pending,
        'resolvedToday': (resolvedTodayData as List).length,
        'urgent': urgent,
      };
    } catch (e) {
      debugPrint('ConsultationRepository.fetchStats error: $e');
      return {'pending': 0, 'resolvedToday': 0, 'urgent': 0};
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final consultationRepositoryProvider = Provider<ConsultationRepository>((ref) {
  return ConsultationRepository(Supabase.instance.client);
});

// All consultations (for officer inbox)
final consultationsProvider = FutureProvider.family<List<Consultation>, String?>((ref, statusFilter) async {
  final repo = ref.read(consultationRepositoryProvider);
  return repo.fetchAllConsultations(statusFilter: statusFilter);
});

// Officer dashboard stats
final officerStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.read(consultationRepositoryProvider);
  return repo.fetchOfficerStats();
});

// Single consultation detail
final consultationDetailProvider = FutureProvider.family<Consultation?, String>((ref, id) async {
  final repo = ref.read(consultationRepositoryProvider);
  return repo.fetchConsultationById(id);
});
