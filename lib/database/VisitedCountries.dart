import 'package:drift/drift.dart';

class VisitedCountries extends Table {
  TextColumn get id => text()();
  TextColumn get countryCode => text()();
  TextColumn get userId => text().withDefault(const Constant('local'))();

  RealColumn get lat => real().withDefault(const Constant(0.0))();
  RealColumn get lng => real().withDefault(const Constant(0.0))();

  DateTimeColumn get visitedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}