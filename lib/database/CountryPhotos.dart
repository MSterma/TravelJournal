import 'package:drift/drift.dart';
import 'VisitedCountries.dart';

class CountryPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get countryId => text().references(VisitedCountries, #id)();
  TextColumn get imagePath => text()();
  TextColumn get userId => text().withDefault(const Constant('local'))();

  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}