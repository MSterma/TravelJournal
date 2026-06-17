import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'CountryPhotos.dart';
import 'VisitedCountries.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [VisitedCountries, CountryPhotos])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        await m.alterTable(TableMigration(visitedCountries));
        await m.alterTable(TableMigration(countryPhotos));
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'travel_journal.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}