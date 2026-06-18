import 'package:drift/drift.dart';

class VisitedCountries extends Table {
  TextColumn get id => text()();
  TextColumn get countryCode => text().unique()();
  DateTimeColumn get visitedAt => dateTime().withDefault(currentDateAndTime)();


  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

