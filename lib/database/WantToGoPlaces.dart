import 'package:drift/drift.dart';

class WantToGoPlaces extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  BoolColumn get isVisited => boolean().withDefault(const Constant(false))();
  DateTimeColumn get visitedAt => dateTime().nullable()();
  TextColumn get userId => text()();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
