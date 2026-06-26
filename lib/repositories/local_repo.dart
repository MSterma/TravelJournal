import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../models/user_stats.dart';

class LocalRepo {
  LocalRepo(this.db);
  final AppDatabase db;
  final _uuid = const Uuid();

  Future<void> markVisited(
      String countryName, String userId, double lat, double lng) async {
    await db.transaction(() async {
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
    });
  }

  Future<bool> checkVisited(String countryName, String userId) async {
    final query = db.select(db.visitedCountries)
      ..where((tbl) =>
          tbl.countryCode.equals(countryName) & tbl.userId.equals(userId));
    final result = await query.get();
    return result.isNotEmpty;
  }

  Future<List<VisitedCountry>> getUnsyncedCountries(String userId) async {
    final query = db.select(db.visitedCountries)
      ..where((tbl) => tbl.isSynced.equals(false) & tbl.userId.equals(userId));
    return await query.get();
  }

  Future<void> markCountriesSynced(List<String> ids) async {
    final query = db.update(db.visitedCountries)..where((tbl) => tbl.id.isIn(ids));
    await query.write(const VisitedCountriesCompanion(isSynced: Value(true)));
  }

  Future<String?> _getCountryId(String countryName, String userId) async {
    final query = db.select(db.visitedCountries)
      ..where((tbl) =>
          tbl.countryCode.equals(countryName) & tbl.userId.equals(userId));
    final results = await query.get();
    if (results.isEmpty) return null;
    return results.first.id;
  }

  Future<void> addPhoto(
      String countryName, String imagePath, String userId) async {
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
      ..where((tbl) =>
          tbl.countryId.equals(countryId) & tbl.userId.equals(userId));
    final results = await query.get();
    return results.map((e) => e.imagePath).toList();
  }

  Future<void> insertFromCloud(String id, String countryCode, String userId,
      double lat, double lng, DateTime visitedAt) async {
    final exists = await (db.select(db.visitedCountries)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (exists != null) return;

    await db.into(db.visitedCountries).insert(
          VisitedCountriesCompanion.insert(
            id: id,
            countryCode: countryCode,
            userId: Value(userId),
            lat: Value(lat),
            lng: Value(lng),
            visitedAt: Value(visitedAt),
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
    await (db.delete(db.visitedCountries)
          ..where((tbl) => tbl.userId.equals(userId)))
        .go();
    await (db.delete(db.countryPhotos)
          ..where((tbl) => tbl.userId.equals(userId)))
        .go();
    await (db.delete(db.travels)..where((tbl) => tbl.userId.equals(userId)))
        .go();
    await (db.delete(db.notes)..where((tbl) => tbl.userId.equals(userId))).go();
  }

  Future<int> addTravel(String name, String userId) async {
    return await db.into(db.travels).insert(
          TravelsCompanion.insert(
            travelName: name,
            userId: userId,
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<List<Travel>> getTravels(String userId) async {
    final query = db.select(db.travels)
      ..where((tbl) => tbl.userId.equals(userId));
    return await query.get();
  }

  Future<int> addNote(String userId, double lat, double lng, String name,
      String? userNote, int? travelId) async {
    return await db.into(db.notes).insert(
          NotesCompanion.insert(
            userId: userId,
            name: name,
            date: DateTime.now(),
            lat: lat,
            lng: lng,
            userNote: Value(userNote),
            travelId: Value(travelId),
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<List<Note>> getNotes(String userId, int? travelId) async {
    final query = db.select(db.notes)..where((tbl) => tbl.userId.equals(userId));
    if (travelId != null) {
      query.where((tbl) => tbl.travelId.equals(travelId));
    } else {
      query.where((tbl) => tbl.travelId.isNull());
    }
    return await query.get();
  }

  Future<List<Note>> getAllNotes(String userId) async {
    final query = db.select(db.notes)..where((tbl) => tbl.userId.equals(userId));
    query.orderBy([(t) => OrderingTerm(expression: t.date)]);
    return await query.get();
  }

  Future<List<String>> getNotePhotos(int noteId) async {
    final query = db.select(db.notePhotos)
      ..where((tbl) => tbl.noteId.equals(noteId));
    final result = await query.get();
    return result.map((e) => e.photoPath).toList();
  }

  Future<void> addNoteWithPhotos(String userId, double lat, double lng,
      String name, String? userNote, int? travelId, List<String> photoPaths) async {
    final noteId = await db.into(db.notes).insert(
          NotesCompanion.insert(
            userId: userId,
            name: name,
            date: DateTime.now(),
            lat: lat,
            lng: lng,
            userNote: Value(userNote),
            travelId: Value(travelId),
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );

    for (final path in photoPaths) {
      await db.into(db.notePhotos).insert(
            NotePhotosCompanion.insert(
              noteId: noteId,
              photoPath: path,
            ),
          );
    }
  }

  Future<List<Travel>> getUnsyncedTravels(String userId) async {
    final query = db.select(db.travels)
      ..where((tbl) => tbl.isSynced.equals(false) & tbl.userId.equals(userId));
    return await query.get();
  }

  Future<List<Note>> getUnsyncedNotes(String userId) async {
    final query = db.select(db.notes)
      ..where((tbl) => tbl.isSynced.equals(false) & tbl.userId.equals(userId));
    return await query.get();
  }

  Future<void> markTravelsSynced(List<int> ids) async {
    final query = db.update(db.travels)..where((tbl) => tbl.id.isIn(ids));
    await query.write(const TravelsCompanion(isSynced: Value(true)));
  }

  Future<void> markNotesSynced(List<int> ids) async {
    final query = db.update(db.notes)..where((tbl) => tbl.id.isIn(ids));
    await query.write(const NotesCompanion(isSynced: Value(true)));
  }

  Future<int> addWantToGoPlace(
      String name, double lat, double lng, String userId) async {
    return await db.into(db.wantToGoPlaces).insert(
          WantToGoPlacesCompanion.insert(
            name: name,
            lat: lat,
            lng: lng,
            userId: userId,
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<List<WantToGoPlace>> getWantToGoPlaces(String userId) async {
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(hours: 24));

    final query = db.select(db.wantToGoPlaces)
      ..where((tbl) =>
          tbl.userId.equals(userId) &
          (tbl.isVisited.equals(false) | tbl.visitedAt.isBiggerThanValue(cutoff)));
    return await query.get();
  }

  Future<void> togglePlaceVisited(int id, bool isVisited) async {
    final query = db.update(db.wantToGoPlaces)..where((tbl) => tbl.id.equals(id));
    await query.write(WantToGoPlacesCompanion(
      isVisited: Value(isVisited),
      visitedAt: Value(isVisited ? DateTime.now() : null),
      isSynced: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<List<WantToGoPlace>> getUnsyncedWantToGoPlaces(String userId) async {
    final query = db.select(db.wantToGoPlaces)
      ..where((tbl) => tbl.isSynced.equals(false) & tbl.userId.equals(userId));
    return await query.get();
  }

  Future<void> markWantToGoPlacesSynced(List<int> ids) async {
    final query = db.update(db.wantToGoPlaces)..where((tbl) => tbl.id.isIn(ids));
    await query.write(const WantToGoPlacesCompanion(isSynced: Value(true)));
  }

  Future<void> insertWantToGoPlaceFromCloud(
    int id,
    String name,
    double lat,
    double lng,
    String userId,
    bool isVisited,
    DateTime? visitedAt,
  ) async {
    final exists = await (db.select(db.wantToGoPlaces)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (exists != null) return;

    await db.into(db.wantToGoPlaces).insert(
          WantToGoPlacesCompanion.insert(
            id: Value(id),
            name: name,
            lat: lat,
            lng: lng,
            userId: userId,
            isVisited: Value(isVisited),
            visitedAt: Value(visitedAt),
            isSynced: const Value(true),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  Future<void> insertTravelFromCloud(
      int id, String name, String userId) async {
    final exists = await (db.select(db.travels)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (exists != null) return;

    await db.into(db.travels).insert(
          TravelsCompanion.insert(
            id: Value(id),
            travelName: name,
            userId: userId,
            isSynced: const Value(true),
          ),
        );
  }

  Future<void> insertNoteFromCloud(
    int id,
    String userId,
    String name,
    DateTime date,
    double lat,
    double lng,
    String? userNote,
    int? travelId, {
    int photoCount = 0,
  }) async {
    final exists = await (db.select(db.notes)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (exists != null) return;

    await db.into(db.notes).insert(
          NotesCompanion.insert(
            id: Value(id),
            userId: userId,
            name: name,
            date: date,
            lat: lat,
            lng: lng,
            userNote: Value(userNote),
            travelId: Value(travelId),
            isSynced: const Value(true),
          ),
        );

    for (int i = 0; i < photoCount; i++) {
      await db.into(db.notePhotos).insert(
            NotePhotosCompanion.insert(
              noteId: id,
              photoPath: '__PLACEHOLDER__',
            ),
          );
    }
  }

  Future<UserStats> getUserStats(String userId) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final monthStart = DateTime(now.year, now.month, 1);

    final travels = await getTravels(userId);
    final totalTrips = travels.length;

    final notes = await getAllNotes(userId);
    final totalNotes = notes.length;
    final todayNotes = notes.where((n) => !n.date.isBefore(todayStart)).length;

    final visits = await getVisitedWithCoords(userId);
    final totalCountries = visits.length;
    final todayCountries =
        visits.where((v) => !v.visitedAt.isBefore(todayStart)).length;

    final countriesThisMonth = visits
        .where((v) => !v.visitedAt.isBefore(monthStart))
        .map((v) => v.countryCode)
        .toSet()
        .toList();

    final countryPhotos = await (db.select(db.countryPhotos)
          ..where((t) => t.userId.equals(userId)))
        .get();
    final noteIds = notes.map((n) => n.id).toList();
    List<NotePhoto> notePhotosList = [];
    if (noteIds.isNotEmpty) {
      notePhotosList = await (db.select(db.notePhotos)
            ..where((t) => t.noteId.isIn(noteIds)))
          .get();
    }
    final totalPhotos = countryPhotos.length + notePhotosList.length;

    final todayNoteIds =
        notes.where((n) => !n.date.isBefore(todayStart)).map((n) => n.id).toList();
    final todayPhotos =
        notePhotosList.where((p) => todayNoteIds.contains(p.noteId)).length;

    List<int> noteActivity = List.filled(30, 0);
    List<int> countryActivity = List.filled(30, 0);
    List<int> combinedActivity = List.filled(30, 0);
    List<int> photoActivity = List.filled(30, 0);

    for (var n in notes) {
      final diff =
          todayStart.difference(DateTime(n.date.year, n.date.month, n.date.day)).inDays;
      if (diff >= 0 && diff < 30) {
        noteActivity[29 - diff]++;
        combinedActivity[29 - diff]++;
      }
    }
    for (var v in visits) {
      final diff = todayStart
          .difference(DateTime(v.visitedAt.year, v.visitedAt.month, v.visitedAt.day))
          .inDays;
      if (diff >= 0 && diff < 30) {
        countryActivity[29 - diff]++;
        combinedActivity[29 - diff]++;
      }
    }

    final Map<int, DateTime> noteDateMap = {for (var n in notes) n.id: n.date};
    final Map<String, DateTime> countryDateMap = {
      for (var v in visits) v.id: v.visitedAt
    };

    for (var p in notePhotosList) {
      final date = noteDateMap[p.noteId];
      if (date != null) {
        final diff =
            todayStart.difference(DateTime(date.year, date.month, date.day)).inDays;
        if (diff >= 0 && diff < 30) photoActivity[29 - diff]++;
      }
    }
    for (var cp in countryPhotos) {
      final date = countryDateMap[cp.countryId];
      if (date != null) {
        final diff =
            todayStart.difference(DateTime(date.year, date.month, date.day)).inDays;
        if (diff >= 0 && diff < 30) photoActivity[29 - diff]++;
      }
    }

    final double dailyAvg = combinedActivity.reduce((a, b) => a + b) / 30.0;

    final dates = <DateTime>{};
    for (var n in notes) {
      dates.add(DateTime(n.date.year, n.date.month, n.date.day));
    }
    for (var v in visits) {
      dates.add(DateTime(v.visitedAt.year, v.visitedAt.month, v.visitedAt.day));
    }
    final sortedDates = dates.toList()..sort((a, b) => b.compareTo(a));

    int streak = 0;
    if (sortedDates.isNotEmpty) {
      DateTime checkDate = todayStart;
      if (!sortedDates.contains(todayStart)) {
        checkDate = todayStart.subtract(const Duration(days: 1));
      }
      if (sortedDates.contains(checkDate)) {
        for (int i = 0; i < sortedDates.length; i++) {
          if (sortedDates.contains(checkDate.subtract(Duration(days: i)))) {
            streak++;
          } else {
            break;
          }
        }
      }
    }

    return UserStats(
      totalPhotos: totalPhotos,
      todayPhotos: todayPhotos,
      totalNotes: totalNotes,
      todayNotes: todayNotes,
      totalCountries: totalCountries,
      todayCountries: todayCountries,
      last30DaysActivity: combinedActivity,
      photosActivity: photoActivity,
      notesActivity: noteActivity,
      countriesActivity: countryActivity,
      dailyAverage: dailyAvg,
      countriesThisMonth: countriesThisMonth,
      totalTrips: totalTrips,
      currentStreak: streak,
    );
  }
}
