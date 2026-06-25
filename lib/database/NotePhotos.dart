import 'package:drift/drift.dart';
import 'Notes.dart';

class NotePhotos extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get noteId => integer().references(Notes, #id)();
  TextColumn get photoPath => text()();
}
