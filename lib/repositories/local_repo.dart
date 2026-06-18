import 'package:uuid/uuid.dart';
import '../database/app_database.dart';

class LocalRepo {
  final AppDatabase db;
  final _uuid = const Uuid();

  LocalRepo(this.db);

  Future<void> markVisited(String countryName) async {
    final exists = await checkVisited(countryName);
    if (exists) return;

    final id = _uuid.v4();
    await db.into(db.visitedCountries).insert(
      VisitedCountriesCompanion.insert(
        id: id,
        countryCode: countryName,
      ),
    );
  }

  Future<bool> checkVisited(String countryName) async {
    final query = db.select(db.visitedCountries)
      ..where((tbl) => tbl.countryCode.equals(countryName));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<String?> _getCountryId(String countryName) async {
    final query = db.select(db.visitedCountries)
      ..where((tbl) => tbl.countryCode.equals(countryName));
    final result = await query.getSingleOrNull();
    return result?.id;
  }

  Future<void> addPhoto(String countryName, String imagePath) async {
    final countryId = await _getCountryId(countryName);
    if (countryId != null) {
      await db.into(db.countryPhotos).insert(
        CountryPhotosCompanion.insert(
          id: _uuid.v4(),
          countryId: countryId,
          imagePath: imagePath,
        ),
      );
    }
  }

  Future<List<String>> getPhotos(String countryName) async {
    final countryId = await _getCountryId(countryName);
    if (countryId == null) return [];

    final query = db.select(db.countryPhotos)
      ..where((tbl) => tbl.countryId.equals(countryId));
    final results = await query.get();
    return results.map((e) => e.imagePath).toList();
  }
}