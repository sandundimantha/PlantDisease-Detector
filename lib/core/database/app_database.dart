import 'package:drift/drift.dart';
import 'connection/connection_stub.dart'
    if (dart.library.io) 'connection/connection_mobile.dart'
    if (dart.library.html) 'connection/connection_web.dart';

import 'tables/cached_diagnoses.dart';
import 'tables/outbox.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [CachedDiagnoses, Outbox])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  @override
  int get schemaVersion => 1;
}
