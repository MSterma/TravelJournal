import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';

class LocalRepo {
  LocalRepo(this.db);
  final AppDatabase db;
  final _uuid = const Uuid();

  Future<void> markVisited(String countryName, String userId, double lat, double lng) async {
    final exists = await checkVisited(countryName, userId);
    if (exists) return;

    final id = _uuid.v4();
    await db.into(db.visitedCountries).insert(
      VisitedCountriesCompanion.insert(
        id: id,
        countryCode: countryName,
        userId: Value(userId),
        lat: Value(lat),
        lng: Value(lng),
        isSynced: const Value(false),
      ),
    );
  }

  Future<bool> checkVisited(String countryName, String userId) async {
    final query = db.select(db.visitedCountries)
      ..where((tbl) => tbl.countryCode.equals(countryName) & tbl.userId.equals(userId));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<List<VisitedCountry>> getUnsyncedCountries(String userId) async {
    final query = db.select(db.visitedCountries)
      ..where((tbl) => tbl.isSynced.equals(false) & tbl.userId.equals(userId));
    return await query.get();
  }

  Future<void> markCountriesSynced(List<String> ids) async {
    final query = db.update(db.visitedCountries)
      ..where((tbl) => tbl.id.isIn(ids));
    await query.write(const VisitedCountriesCompanion(isSynced: Value(true)));
  }

  Future<String?> _getCountryId(String countryName, String userId) async {
    final query = db.select(db.visitedCountries)
      ..where((tbl) => tbl.countryCode.equals(countryName) & tbl.userId.equals(userId));
    final results = await query.get();
    if (results.isEmpty) return null;
    return results.first.id;
  }

  Future<void> addPhoto(String countryName, String imagePath, String userId) async {
    final countryId = await _getCountryId(countryName, userId);
    if (countryId != null) {
      await db.into(db.countryPhotos).insert(
        CountryPhotosCompanion.insert(
          id: _uuid.v4(),
          countryId: countryId,
          imagePath: imagePath,
          userId: Value(userId),
          isSynced: const Value(false),
        ),
      );
    }
  }

  Future<List<String>> getPhotos(String countryName, String userId) async {
    final countryId = await _getCountryId(countryName, userId);
    if (countryId == null) return [];

    final query = db.select(db.countryPhotos)
      ..where((tbl) => tbl.countryId.equals(countryId) & tbl.userId.equals(userId));
    final results = await query.get();
    return results.map((e) => e.imagePath).toList();
  }

  Future<void> insertFromCloud(String countryCode, String userId, double lat, double lng) async {
    final exists = await checkVisited(countryCode, userId);
    if (exists) return;

    await db.into(db.visitedCountries).insert(
      VisitedCountriesCompanion.insert(
        id: _uuid.v4(),
        countryCode: countryCode,
        userId: Value(userId),
        lat: Value(lat),
        lng: Value(lng),
        isSynced: const Value(true),
      ),
    );
  }

  Future<List<VisitedCountry>> getVisitedWithCoords(String userId) async {
    final query = db.select(db.visitedCountries)
      ..where((tbl) => tbl.userId.equals(userId));
    return await query.get();
  }

  Future<void> clearUserData(String userId) async {
    await (db.delete(db.visitedCountries)..where((tbl) => tbl.userId.equals(userId))).go();
    await (db.delete(db.countryPhotos)..where((tbl) => tbl.userId.equals(userId))).go();
  }
}