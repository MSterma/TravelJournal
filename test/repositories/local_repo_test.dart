import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_journal/database/app_database.dart';
import 'package:travel_journal/repositories/local_repo.dart';
import '../utils/race_detector.dart';

void main() {
  late AppDatabase db;
  late LocalRepo localRepo;

  setUp(() {
    db = AppDatabase.memory();
    localRepo = LocalRepo(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('LocalRepo Race Condition Tests', () {
    test(
      'markVisited should not create duplicate entries when called concurrently',
      () async {
        const countryName = 'Testland';
        const userId = 'user123';
        const lat = 10.0;
        const lng = 20.0;

        await RaceDetector.run(
          100,
          () => localRepo.markVisited(countryName, userId, lat, lng),
        );

        final results =
            await (db.select(db.visitedCountries)..where(
                  (t) =>
                      t.countryCode.equals(countryName) &
                      t.userId.equals(userId),
                ))
                .get();

        expect(
          results.length,
          1,
          reason: 'Should only have 1 entry for the same country and user',
        );
      },
    );

    test('addNoteWithPhotos should handle concurrent calls safely', () async {
      const userId = 'user123';
      const lat = 10.0;
      const lng = 20.0;
      const name = 'My Note';
      final photos = ['path/1.jpg', 'path/2.jpg'];

      await RaceDetector.run(
        5,
        () => localRepo.addNoteWithPhotos(
          userId,
          lat,
          lng,
          name,
          'note',
          null,
          photos,
        ),
      );

      final notes = await localRepo.getAllNotes(userId);
      expect(notes.length, 5);

      for (final note in notes) {
        final notePhotos = await localRepo.getNotePhotos(note.id);
        expect(notePhotos.length, 2);
      }
    });
  });

  group('LocalRepo Business Logic Tests', () {
    test('getWantToGoPlaces should filter correctly', () async {
      const userId = 'user1';

      await localRepo.addWantToGoPlace('Place 1', 1.0, 1.0, userId);
      await localRepo.addWantToGoPlace('Place 2', 2.0, 2.0, userId);

      final placesBefore = await localRepo.getWantToGoPlaces(userId);
      expect(placesBefore.length, 2);

      // Mark one as visited
      final place1Id = placesBefore.firstWhere((p) => p.name == 'Place 1').id;
      await localRepo.togglePlaceVisited(place1Id, true);

      final placesAfter = await localRepo.getWantToGoPlaces(userId);
      // It should still be there because visitedAt is recent (within 24h)
      expect(placesAfter.length, 2);
      expect(placesAfter.any((p) => p.name == 'Place 1' && p.isVisited), true);
    });
  });
}
