import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/local_repo.dart';

class SyncService {
  SyncService(this.localRepo, this.firestore);
  final LocalRepo localRepo;
  final FirebaseFirestore firestore;

  Future<void> syncCloudToLocal(String userId) async {
    try {
      final userDoc = firestore.collection('users').doc(userId);

      final visitedSnapshot = await userDoc.collection('visited').get();
      for (final doc in visitedSnapshot.docs) {
        final data = doc.data();
        if (data['countryCode'] == null) continue;
        final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;
        final dateStr = data['visitedAt'] as String?;
        final visitedAt =
            dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

        await localRepo.insertFromCloud(
            doc.id, data['countryCode'], userId, lat, lng, visitedAt);
      }

      final travelsSnapshot = await userDoc.collection('travels').get();
      for (final doc in travelsSnapshot.docs) {
        final data = doc.data();
        final id = int.tryParse(doc.id);
        if (id == null) continue;
        await localRepo.insertTravelFromCloud(
            id, data['travelName'] ?? 'Unnamed', userId);
      }

      final notesSnapshot = await userDoc.collection('notes').get();
      for (final doc in notesSnapshot.docs) {
        final data = doc.data();
        final id = int.tryParse(doc.id);
        if (id == null) continue;

        final dateStr = data['date'] as String?;
        final date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();

        await localRepo.insertNoteFromCloud(
          id,
          userId,
          data['name'] ?? 'Unnamed',
          date,
          (data['lat'] as num?)?.toDouble() ?? 0.0,
          (data['lng'] as num?)?.toDouble() ?? 0.0,
          data['userNote'],
          data['travelId'] as int?,
          photoCount: data['photoCount'] as int? ?? 0,
        );
      }

      final wantToGoSnapshot = await userDoc.collection('want_to_go').get();
      for (final doc in wantToGoSnapshot.docs) {
        final data = doc.data();
        final id = int.tryParse(doc.id);
        if (id == null) continue;

        final visitedAtStr = data['visitedAt'] as String?;
        final visitedAt =
            visitedAtStr != null ? DateTime.parse(visitedAtStr) : null;

        await localRepo.insertWantToGoPlaceFromCloud(
          id,
          data['name'] ?? 'Unnamed',
          (data['lat'] as num?)?.toDouble() ?? 0.0,
          (data['lng'] as num?)?.toDouble() ?? 0.0,
          userId,
          data['isVisited'] as bool? ?? false,
          visitedAt,
        );
      }
    } catch (e) {
    }
  }

  Future<void> syncLocalToCloud(String userId) async {
    try {
      final userDoc = firestore.collection('users').doc(userId);
      final batch = firestore.batch();

      final unsyncedCountries = await localRepo.getUnsyncedCountries(userId);
      for (final country in unsyncedCountries) {
        final docRef = userDoc.collection('visited').doc(country.id);
        batch.set(docRef, {
          'countryCode': country.countryCode,
          'visitedAt': country.visitedAt.toIso8601String(),
          'lat': country.lat,
          'lng': country.lng,
        });
      }
      final unsyncedTravels = await localRepo.getUnsyncedTravels(userId);
      for (final travel in unsyncedTravels) {
        final docRef = userDoc.collection('travels').doc(travel.id.toString());
        batch.set(docRef, {
          'travelName': travel.travelName,
          'userId': travel.userId,
        });
      }
      final unsyncedNotes = await localRepo.getUnsyncedNotes(userId);
      for (final note in unsyncedNotes) {
        final photos = await localRepo.getNotePhotos(note.id);
        final docRef = userDoc.collection('notes').doc(note.id.toString());
        batch.set(docRef, {
          'name': note.name,
          'userId': note.userId,
          'date': note.date.toIso8601String(),
          'lat': note.lat,
          'lng': note.lng,
          'userNote': note.userNote,
          'travelId': note.travelId,
          'photoCount': photos.length, // MOCKING PHOTOS
        });
      }

      if (unsyncedNotes.isNotEmpty) {
        await localRepo.markNotesSynced(unsyncedNotes.map((e) => e.id).toList());
      }

      final unsyncedWantToGo = await localRepo.getUnsyncedWantToGoPlaces(userId);
      for (final place in unsyncedWantToGo) {
        final docRef = userDoc.collection('want_to_go').doc(place.id.toString());
        batch.set(docRef, {
          'name': place.name,
          'lat': place.lat,
          'lng': place.lng,
          'userId': place.userId,
          'isVisited': place.isVisited,
          'visitedAt': place.visitedAt?.toIso8601String(),
        });
      }

      await batch.commit();
      if (unsyncedCountries.isNotEmpty) {
        await localRepo.markCountriesSynced(unsyncedCountries.map((e) => e.id).toList());
      }
      if (unsyncedTravels.isNotEmpty) {
        await localRepo.markTravelsSynced(unsyncedTravels.map((e) => e.id).toList());
      }
      if (unsyncedNotes.isNotEmpty) {
        await localRepo.markNotesSynced(unsyncedNotes.map((e) => e.id).toList());
      }
      if (unsyncedWantToGo.isNotEmpty) {
        await localRepo.markWantToGoPlacesSynced(unsyncedWantToGo.map((e) => e.id).toList());
      }
    } catch (e) {

    }
  }

  Future<void> performFullSync(String userId) async {
    await syncCloudToLocal(userId);
    await syncLocalToCloud(userId);
  }

  Future<void> clearCloudData(String userId) async {
    try {
      final userDoc = firestore.collection('users').doc(userId);
      final batch = firestore.batch();

      final collections = ['visited', 'travels', 'notes', 'want_to_go'];
      for (final col in collections) {
        final snapshot = await userDoc.collection(col).get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
    } catch (e) {
    }
  }
}
