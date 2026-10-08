import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:plant_disease_detector/models/agri_officer.dart';
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
      // Rethrow so "My Requests" shows an error instead of an empty history.
      debugPrint('ConsultationRepository.fetchFarmer error: $e');
      rethrow;
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

  // ── Create a new consultation (farmer → officer escalation) ───────────────
  // Throws on failure so the request form can tell the farmer it was not sent.
  Future<Consultation> createConsultation({
    required String farmerId,
    String? scanId,
    String? diseaseName,
    String? severity,
    String? imageUrl,
    String? location,
    String? notes,
  }) async {
    final data = await _client.from('consultations').insert({
      'farmer_id': farmerId,
      'scan_id': scanId,
      'disease_name': diseaseName,
      'severity': severity ?? 'medium',
      'image_url': imageUrl,
      'location': location,
      'notes': notes,
      'status': 'pending',
    }).select().single();
    return Consultation.fromJson(data);
  }

  // ── Add a message to a consultation thread ────────────────────────────────
  Future<void> sendMessage({
    required String consultationId,
    required String senderId,
    required String senderRole,
    required String content,
  }) async {
    await _client.from('consultation_messages').insert({
      'consultation_id': consultationId,
      'sender_id': senderId,
      'sender_role': senderRole,
      'content': content,
    });
  }

  // ── Farmer withdraws a request that no officer has picked up yet ──────────
  // Farmers have UPDATE (not DELETE) rights on their own rows, so a cancel is
  // a status change; officers still see it in the inbox as "Cancelled".
  Future<void> cancelConsultation(String consultationId) async {
    final rows = await _client
        .from('consultations')
        .update({'status': 'cancelled'})
        .eq('id', consultationId)
        .eq('status', 'pending')
        .select('id');
    if ((rows as List).isEmpty) {
      throw Exception('Request can no longer be cancelled.');
    }
  }

  // ── Update consultation status ─────────────────────────────────────────────
  Future<void> updateStatus(String consultationId, String status) async {
    try {
      final updates = <String, dynamic>{'status': status};
      if (status == 'resolved') {
        updates['resolved_at'] = DateTime.now().toUtc().toIso8601String();
      }
      await _client.from('consultations').update(updates).eq('id', consultationId);
    } catch (e) {
      debugPrint('ConsultationRepository.updateStatus error: $e');
    }
  }

  // ── Assign officer to consultation ────────────────────────────────────────
  // Throws so the UI can report failure. RLS blocks return 0 rows rather than
  // an error, so the affected rows are checked explicitly.
  // Only an unassigned pending case can be taken, so a stale inbox cannot
  // reopen a cancelled case or take over another officer's case.
  Future<void> assignOfficer(String consultationId, String officerId) async {
    final rows = await _client
        .from('consultations')
        .update({'officer_id': officerId, 'status': 'open'})
        .eq('id', consultationId)
        .eq('status', 'pending')
        .isFilter('officer_id', null)
        .select('id');
    if ((rows as List).isEmpty) {
      throw Exception('This case was already accepted by another officer or cancelled by the farmer.');
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
      // Fetch resolved today specifically
      final resolvedTodayData = await _client
          .from('consultations')
          .select('id')
          .eq('status', 'resolved')
          .gte('resolved_at', DateTime(today.year, today.month, today.day).toUtc().toIso8601String());
      
      final urgent = list
          .where((c) => c['severity'] == 'high' && c['status'] != 'resolved' && c['status'] != 'cancelled')
          .length;

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

// Logged-in farmer's own requests (Expert Consult → "My Requests")
final myConsultationsProvider = FutureProvider.autoDispose<List<Consultation>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];
  return ref.read(consultationRepositoryProvider).fetchFarmerConsultations(userId);
});

// Live status of one request. The realtime row has no profile joins, so the
// joined fields are re-fetched whenever the row changes (e.g. officer accepts).
final liveConsultationProvider =
    StreamProvider.autoDispose.family<Consultation?, String>((ref, id) async* {
  final repo = ref.read(consultationRepositoryProvider);
  final stream = Supabase.instance.client
      .from('consultations')
      .stream(primaryKey: ['id'])
      .eq('id', id);
  await for (final rows in stream) {
    if (rows.isEmpty) {
      yield null;
      continue;
    }
    yield await repo.fetchConsultationById(id) ?? Consultation.fromJson(rows.first);
  }
});

// Live messages for one request (farmer side; officer side uses ChatNotifier)
final consultationMessagesProvider =
    StreamProvider.autoDispose.family<List<ConsultationMessage>, String>((ref, id) {
  return Supabase.instance.client
      .from('consultation_messages')
      .stream(primaryKey: ['id'])
      .eq('consultation_id', id)
      .order('created_at', ascending: true)
      .map((rows) => rows.map(ConsultationMessage.fromJson).toList());
});

// Agricultural officers shown on the Expert Consult screen
final agriOfficersProvider = FutureProvider.autoDispose<List<AgriOfficer>>((ref) async {
  final data = await Supabase.instance.client
      .from('agri_officers')
      .select()
      .order('name', ascending: true);
  return (data as List).map((o) => AgriOfficer.fromJson(o)).toList();
});
