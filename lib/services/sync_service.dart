import 'package:cloud_firestore/cloud_firestore.dart';
import '../repositories/local_repo.dart';

class SyncService {
  SyncService(this.localRepo, this.firestore);
  final LocalRepo localRepo;
  final FirebaseFirestore firestore;

  Future<void> syncCloudToLocal(String userId) async {
    try {
      final userDoc = firestore.collection('users').doc(userId);
      final snapshot = await userDoc.collection('visited').get();

      for (final doc in snapshot.docs) {
        final data = doc.data();

        if (data['countryCode'] == null) continue;

        final lat = (data['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (data['lng'] as num?)?.toDouble() ?? 0.0;

        await localRepo.insertFromCloud(data['countryCode'], userId, lat, lng);
      }
    } catch (e) {
    }
  }

  Future<void> syncLocalToCloud(String userId) async {
    try {
      final unsynced = await localRepo.getUnsyncedCountries(userId);
      if (unsynced.isEmpty) return;

      final batch = firestore.batch();
      final userDoc = firestore.collection('users').doc(userId);

      for (final country in unsynced) {
        final docRef = userDoc.collection('visited').doc(country.id);
        batch.set(docRef, {
          'countryCode': country.countryCode,
          'visitedAt': country.visitedAt.toIso8601String(),
          'lat': country.lat,
          'lng': country.lng,
        });
      }
      await batch.commit();

      final ids = unsynced.map((e) => e.id).toList();
      await localRepo.markCountriesSynced(ids);
    } catch (e) {
    }
  }

  Future<void> performFullSync(String userId) async {
    await syncCloudToLocal(userId);
    await syncLocalToCloud(userId);
  }

  Future<void> clearCloudData(String userId) async {
    try {
      final collection = firestore.collection('users').doc(userId).collection('visited');
      final snapshots = await collection.get();

      final batch = firestore.batch();
      for (final doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
    }
  }
}