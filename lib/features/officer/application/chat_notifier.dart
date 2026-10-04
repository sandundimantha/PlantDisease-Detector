import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:plant_disease_detector/models/consultation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChatNotifier — Real-time chat using Supabase Realtime
// ─────────────────────────────────────────────────────────────────────────────
class ChatNotifier extends FamilyAsyncNotifier<List<ConsultationMessage>, String> {
  // Not final: the family provider is kept alive, so reopening the same case
  // calls initialize() again on the same notifier.
  late String _consultationId;
  RealtimeChannel? _channel;

  @override
  Future<List<ConsultationMessage>> build(String arg) async {
    // Cleanup subscription on dispose
    ref.onDispose(() {
      _channel?.unsubscribe();
    });
    return [];
  }

  /// Call this after the notifier is created, before using it
  Future<void> initialize(String consultationId) async {
    _consultationId = consultationId;
    await _fetchMessages();
    _subscribeToRealtime();
  }

  Future<void> _fetchMessages() async {
    state = const AsyncValue.loading();
    try {
      final data = await Supabase.instance.client
          .from('consultation_messages')
          .select('''
            *,
            sender_profile:sender_id(full_name, avatar_url)
          ''')
          .eq('consultation_id', _consultationId)
          .order('created_at', ascending: true);

      final messages = (data as List)
          .map((e) => ConsultationMessage.fromJson(e))
          .toList();
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      debugPrint('ChatNotifier._fetchMessages error: $e');
    }
  }

  void _subscribeToRealtime() {
    // Cancel any existing subscription
    _channel?.unsubscribe();

    _channel = Supabase.instance.client
        .channel('consultation_$_consultationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'consultation_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'consultation_id',
            value: _consultationId,
          ),
          callback: (payload) {
            _onNewMessage(payload.newRecord);
          },
        )
        .subscribe();
  }

  void _onNewMessage(Map<String, dynamic> record) {
    final currentMessages = state.valueOrNull ?? [];
    final alreadyExists = currentMessages.any((m) => m.id == record['id']);
    if (alreadyExists) return;

    final newMessage = ConsultationMessage.fromJson({
      ...record,
      'sender_profile': null, // Real-time events don't include joins
    });

    // Our own sends were already shown optimistically with a temp_ id; swap
    // that placeholder for the stored row instead of showing it twice.
    final tempIndex = currentMessages.indexWhere((m) =>
        m.id.startsWith('temp_') &&
        m.senderId == newMessage.senderId &&
        m.content == newMessage.content);
    if (tempIndex != -1) {
      final updated = [...currentMessages]..[tempIndex] = newMessage;
      state = AsyncValue.data(updated);
      return;
    }
    state = AsyncValue.data([...currentMessages, newMessage]);
  }

  /// Send a message (officer or farmer)
  Future<void> sendMessage({
    required String content,
    required String senderRole,
  }) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null || content.trim().isEmpty) return;

    // Optimistic update — add message immediately to UI
    final optimisticMsg = ConsultationMessage(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      consultationId: _consultationId,
      senderId: user.id,
      senderRole: senderRole,
      content: content.trim(),
      createdAt: DateTime.now(),
    );

    final currentMessages = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentMessages, optimisticMsg]);

    try {
      await client.from('consultation_messages').insert({
        'consultation_id': _consultationId,
        'sender_id': user.id,
        'sender_role': senderRole,
        'content': content.trim(),
      });
    } catch (e) {
      // Rollback optimistic update on error
      final msgs = state.valueOrNull ?? [];
      state = AsyncValue.data(msgs.where((m) => m.id != optimisticMsg.id).toList());
      debugPrint('ChatNotifier.sendMessage error: $e');
    }
  }

  /// Mark consultation as resolved. Throws if nothing was updated so the
  /// screen does not report success for a case that is still open.
  Future<void> markResolved() async {
    final client = Supabase.instance.client;
    final rows = await client
        .from('consultations')
        .update({
          // RLS only lets the assigned officer close a case; resolving an
          // unaccepted case assigns it to the officer who answered it.
          'officer_id': client.auth.currentUser?.id,
          'status': 'resolved',
          'resolved_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', _consultationId)
        .select('id');
    if ((rows as List).isEmpty) {
      throw Exception('Case could not be resolved.');
    }
  }
}

// Family provider — one notifier per consultation ID
final chatProvider = AsyncNotifierProviderFamily<ChatNotifier, List<ConsultationMessage>, String>(
  ChatNotifier.new,
);
