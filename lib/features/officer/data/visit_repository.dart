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

  // ── Officer cancels a visit ───────────────────────────────────────────────
  // A visit a farmer requested or is linked to is kept as 'cancelled' so the
  // farmer's list shows the cancellation; a private plan is deleted outright.
  Future<void> cancelVisit(OfficerVisit visit) async {
    if (visit.farmerId == null) return deleteVisit(visit.id);
    final rows = await _client
        .from('officer_visits')
        .update({'status': 'cancelled', 'updated_at': _now})
        .eq('id', visit.id)
        .select('id');
    _ensureRows(rows, 'Visit could not be cancelled.');
  }

  // ── Create: farmer asks an officer to visit (Officer Location Map) ───────
  // officer_id stays null until an officer accepts it on the AO Dashboard.
  Future<void> requestVisit({
    required String farmerId,
    required String farmerName,
    required String agriOfficerId,
    required String village,
    required String reason,
    DateTime? preferredDate,
  }) async {
    await _client.from('officer_visits').insert({
      'farmer_id': farmerId,
      'agri_officer_id': agriOfficerId,
      'farmer_name': farmerName,
      'village': village,
      'reason': reason,
      'scheduled_for': preferredDate?.toUtc().toIso8601String(),
      'status': 'requested',
    });
  }

  // ── Delete: farmer withdraws a request no officer has accepted yet ────────
  Future<void> cancelRequest(String visitId) async {
    final rows = await _client
        .from('officer_visits')
        .delete()
        .eq('id', visitId)
        .eq('status', 'requested')
        .select('id');
    _ensureRows(rows, 'An officer has already scheduled this visit, so it can no longer be cancelled.');
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

/// Visits on this officer's schedule plus open farmer requests addressed to
/// them (or to a directory officer with no account), live.
/// Order: farmer requests first, then by date; completed visits last.
final officerVisitsProvider = StreamProvider.autoDispose<List<OfficerVisit>>((ref) async* {
  final client = Supabase.instance.client;
  final me = client.auth.currentUser?.id;

  // Directory entry id -> linked officer account (null = anyone may take it).
  // Re-read on every change so newly linked officers are respected.
  Future<Map<String, String?>> loadOwners() async => {
        for (final row in await client.from('agri_officers').select('id, profile_id'))
          row['id'] as String: row['profile_id'] as String?,
      };

  yield* client
      .from('officer_visits')
      .stream(primaryKey: ['id'])
      .asyncMap((rows) async {
        final owners = await loadOwners();
        bool addressedToMe(OfficerVisit v) {
          final target = v.agriOfficerId;
          if (target == null) return true;
          final owner = owners[target];
          return owner == null || owner == me;
        }

        final visits = rows
            .map(OfficerVisit.fromJson)
            .where((v) =>
                v.status != 'cancelled' &&
                (v.officerId == me || (v.isRequest && addressedToMe(v))))
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

/// The signed-in farmer's own visit requests, newest first, live.
final myVisitRequestsProvider = StreamProvider.autoDispose<List<OfficerVisit>>((ref) {
  final me = Supabase.instance.client.auth.currentUser?.id;
  if (me == null) return Stream.value(const []);
  return Supabase.instance.client
      .from('officer_visits')
      .stream(primaryKey: ['id'])
      .eq('farmer_id', me)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(OfficerVisit.fromJson).toList());
});

class OnDutyNotifier extends AutoDisposeAsyncNotifier<bool> {
  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  @override
  Future<bool> build() async {
    final userId = _userId;
    if (userId == null) return true;
    return ref.read(visitRepositoryProvider).fetchOnDuty(userId);
  }

  bool _saving = false;

  /// Optimistically flips the status; reverts and rethrows if the save fails.
  /// Returns false (no change) while a previous save is still in flight, so
  /// rapid taps cannot leave the UI and the database disagreeing.
  Future<bool> toggle() async {
    final userId = _userId;
    final current = state.valueOrNull ?? true;
    if (userId == null || _saving) return false;
    _saving = true;
    state = AsyncValue.data(!current);
    try {
      await ref.read(visitRepositoryProvider).setOnDuty(userId, !current);
      return true;
    } catch (e) {
      state = AsyncValue.data(current);
      rethrow;
    } finally {
      _saving = false;
    }
  }
}

final onDutyProvider = AsyncNotifierProvider.autoDispose<OnDutyNotifier, bool>(OnDutyNotifier.new);
