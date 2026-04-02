import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    LocalJobs,
    LocalRoutes,
    LocalRouteStops,
    LocalServiceLocations,
    LocalWorkerPingsOutbox,
    LocalGeofenceEventsOutbox,
    SyncQueue,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'fsm_app.sqlite'));
    return NativeDatabase(file);
  });
}