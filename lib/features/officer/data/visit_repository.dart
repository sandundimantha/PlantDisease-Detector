import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:plant_disease_detector/models/officer_visit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VisitRepository — officer field visits (AO Dashboard) and on-duty status.
// Writes throw on failure; RLS-blocked writes return no rows instead of an
// error, so affected rows are checked explicitly.
// ─────────────────────────────────────────────────────────────────────────────
class VisitRepository {
  final SupabaseClient _client;

  VisitRepository(this._client);

  String get _now => DateTime.now().toUtc().toIso8601String();

  void _ensureRows(dynamic rows, String message) {
    if ((rows as List).isEmpty) throw Exception(message);
  }

  // ── Create: officer plans a visit (Quick Action) ──────────────────────────
  Future<void> scheduleVisit({
    required String officerId,
    required String farmerName,
    required String village,
    required DateTime scheduledFor,
    String? reason,
    String? farmerId,
    String? consultationId,
  }) async {
    await _client.from('officer_visits').insert({
      'officer_id': officerId,
      'farmer_id': farmerId,
      'consultation_id': consultationId,
      'farmer_name': farmerName,
      'village': village,
      'reason': reason,
      'scheduled_for': scheduledFor.toUtc().toIso8601String(),
      'status': 'scheduled',
    });
  }

  // ── Update: officer takes a farmer's visit request ────────────────────────
  Future<void> acceptRequest(String visitId, String officerId, DateTime scheduledFor) async {
    final rows = await _client
        .from('officer_visits')
        .update({
          'officer_id': officerId,
          'status': 'scheduled',
          'scheduled_for': scheduledFor.toUtc().toIso8601String(),
          'updated_at': _now,
        })
        .eq('id', visitId)
        .eq('status', 'requested')
        .select('id');
    _ensureRows(rows, 'This request was already taken or withdrawn.');
  }

  // ── Update: move a visit to another date/time ─────────────────────────────
  Future<void> reschedule(String visitId, DateTime scheduledFor) async {
    final rows = await _client
        .from('officer_visits')
        .update({'scheduled_for': scheduledFor.toUtc().toIso8601String(), 'updated_at': _now})
        .eq('id', visitId)
        .select('id');
    _ensureRows(rows, 'Visit could not be rescheduled.');
  }

  // ── Update: visit done ────────────────────────────────────────────────────
  Future<void> markCompleted(String visitId) async {
    final rows = await _client
        .from('officer_visits')
        .update({'status': 'completed', 'updated_at': _now})
        .eq('id', visitId)
        .select('id');
    _ensureRows(rows, 'Visit could not be updated.');
  }

  // ── Delete: officer cancels one of their own visits ───────────────────────
  Future<void> deleteVisit(String visitId) async {
    final rows = await _client.from('officer_visits').delete().eq('id', visitId).select('id');
    _ensureRows(rows, 'Visit could not be cancelled.');
  }

  // ── On-duty status (AO Dashboard Online / Offline toggle) ─────────────────
  Future<bool> fetchOnDuty(String userId) async {
    final row = await _client.from('profiles').select('is_on_duty').eq('id', userId).maybeSingle();
    return row?['is_on_duty'] as bool? ?? true;
  }

  Future<void> setOnDuty(String userId, bool onDuty) async {
    final rows = await _client
        .from('profiles')
        .update({'is_on_duty': onDuty})
        .eq('id', userId)
        .select('id');
    _ensureRows(rows, 'Status could not be saved.');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final visitRepositoryProvider = Provider<VisitRepository>((ref) {
  return VisitRepository(Supabase.instance.client);
});

/// Visits on this officer's schedule plus open farmer requests, live.
/// Order: farmer requests first, then by date; completed visits last.
final officerVisitsProvider = StreamProvider.autoDispose<List<OfficerVisit>>((ref) {
  final me = Supabase.instance.client.auth.currentUser?.id;
  return Supabase.instance.client
      .from('officer_visits')
      .stream(primaryKey: ['id'])
      .map((rows) {
        final visits = rows
            .map(OfficerVisit.fromJson)
            .where((v) => v.status != 'cancelled' && (v.officerId == me || v.isRequest))
            .toList();
        int rank(OfficerVisit v) => v.isRequest ? 0 : (v.isCompleted ? 2 : 1);
        visits.sort((a, b) {
          final byRank = rank(a).compareTo(rank(b));
          if (byRank != 0) return byRank;
          final aDate = a.scheduledFor ?? a.createdAt;
          final bDate = b.scheduledFor ?? b.createdAt;
          return a.isCompleted ? bDate.compareTo(aDate) : aDate.compareTo(bDate);
        });
        return visits;
      });
});

class OnDutyNotifier extends AutoDisposeAsyncNotifier<bool> {
  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  Future<bool> build() async {
    final userId = _userId;
    if (userId == null) return true;
    return ref.read(visitRepositoryProvider).fetchOnDuty(userId);
  }

  /// Optimistically flips the status; reverts and rethrows if the save fails.
  Future<void> toggle() async {
    final userId = _userId;
    final current = state.valueOrNull ?? true;
    if (userId == null) return;
    state = AsyncValue.data(!current);
    try {
      await ref.read(visitRepositoryProvider).setOnDuty(userId, !current);
    } catch (e) {
      state = AsyncValue.data(current);
      rethrow;
    }
  }
}

final onDutyProvider = AsyncNotifierProvider.autoDispose<OnDutyNotifier, bool>(OnDutyNotifier.new);
