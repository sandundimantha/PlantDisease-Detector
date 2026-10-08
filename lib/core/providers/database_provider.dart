import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../sync/outbox_processor.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final outboxProcessorProvider = Provider<OutboxProcessor>((ref) {
  final db = ref.watch(databaseProvider);
  return OutboxProcessor(db);
});

/// Queued uploads that have not reached Supabase yet (newest first).
final pendingUploadsProvider = StreamProvider<List<OutboxData>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.outbox)
        ..where((t) => t.status.equals('synced').not())
        ..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
      .watch();
});
