import 'package:drift/drift.dart';

class LocalJobs extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get serviceLocationId => text()();
  TextColumn get serviceType => text()();
  TextColumn get status => text()();
  IntColumn get priority => integer().withDefault(const Constant(3))();
  DateTimeColumn get scheduledDate => dateTime().nullable()();
  DateTimeColumn get timeWindowStart => dateTime().nullable()();
  DateTimeColumn get timeWindowEnd => dateTime().nullable()();
  IntColumn get estimatedDurationMin => integer()();
  TextColumn get requiredSkillTagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get assignedWorkerId => text().nullable()();
  TextColumn get routeStopId => text().nullable()();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalRoutes extends Table {
  TextColumn get id => text()();
  DateTimeColumn get routeDate => dateTime()();
  TextColumn get workerId => text()();
  TextColumn get status => text()();
  TextColumn get optimizationProvider => text().nullable()();
  TextColumn get optimizationPayloadJson => text().nullable()();
  IntColumn get totalDistanceM => integer().nullable()();
  IntColumn get totalDurationSec => integer().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalRouteStops extends Table {
  TextColumn get id => text()();
  TextColumn get routeId => text()();
  TextColumn get jobId => text()();
  IntColumn get stopOrder => integer()();
  DateTimeColumn get plannedArrival => dateTime().nullable()();
  DateTimeColumn get plannedDeparture => dateTime().nullable()();
  DateTimeColumn get actualArrival => dateTime().nullable()();
  DateTimeColumn get actualDeparture => dateTime().nullable()();
  TextColumn get stopStatus => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalServiceLocations extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text()();
  TextColumn get label => text().nullable()();
  TextColumn get addressLine1 => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  IntColumn get geofenceRadiusM => integer().withDefault(const Constant(50))();

  @override
  Set<Column> get primaryKey => {id};
}

class LocalWorkerPingsOutbox extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get workerId => text()();
  TextColumn get routeId => text().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get accuracyM => real().nullable()();
  RealColumn get speedMps => real().nullable()();
  RealColumn get headingDeg => real().nullable()();
  RealColumn get batteryPct => real().nullable()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}

class LocalGeofenceEventsOutbox extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get workerId => text()();
  TextColumn get jobId => text()();
  TextColumn get routeId => text().nullable()();
  TextColumn get eventType => text()();
  DateTimeColumn get eventAt => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  RealColumn get accuracyM => real().nullable()();
  IntColumn get dwellSeconds => integer().nullable()();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // insert/update/delete
  TextColumn get payloadJson => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}