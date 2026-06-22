import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'CountryPhotos.dart';
import 'VisitedCountries.dart';
import 'Travels.dart';
import 'Notes.dart';
import 'NotePhotos.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  VisitedCountries,
  CountryPhotos,
  Travels,
  Notes,
  NotePhotos,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from == 1) {
        await m.alterTable(TableMigration(visitedCountries));
        await m.alterTable(TableMigration(countryPhotos));
      }
      if (from < 3) {
        await m.addColumn(visitedCountries, visitedCountries.lat);
        await m.addColumn(visitedCountries, visitedCountries.lng);
      }
      if (from < 4) {
        await m.createTable(travels);
        await m.createTable(notes);
        await m.createTable(notePhotos);
      }
      if (from < 5) {
        await m.addColumn(notes, notes.name);
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