import 'package:drift/drift.dart';

class Travels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get travelName => text()();
  TextColumn get userId => text()();
}
