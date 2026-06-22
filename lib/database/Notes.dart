import 'package:drift/drift.dart';
import 'Travels.dart';

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get userId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get userNote => text().nullable()();
  IntColumn get travelId => integer().nullable().references(Travels, #id)();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
