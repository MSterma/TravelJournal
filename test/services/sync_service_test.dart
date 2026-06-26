import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_journal/services/sync_service.dart';
import 'package:travel_journal/repositories/local_repo.dart';
import 'package:travel_journal/database/app_database.dart';
import '../utils/race_detector.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockWriteBatch extends Mock implements WriteBatch {}

void main() {
  late SyncService syncService;
  late LocalRepo localRepo;
  late AppDatabase db;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    db = AppDatabase.memory();
    localRepo = LocalRepo(db);
    mockFirestore = MockFirebaseFirestore();
    syncService = SyncService(localRepo, mockFirestore);
  });

  tearDown(() async {
    await db.close();
  });

  group('SyncService Race Condition Tests', () {
    test('performFullSync should handle concurrent calls', () async {
      const userId = 'user123';

      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockSubCollection = MockCollectionReference();
      final mockSnapshot = MockQuerySnapshot();
      final mockBatch = MockWriteBatch();

      when(() => mockFirestore.collection(any())).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDoc);
      when(() => mockDoc.collection(any())).thenReturn(mockSubCollection);
      when(() => mockSubCollection.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.docs).thenReturn([]);
      when(() => mockFirestore.batch()).thenReturn(mockBatch);
      when(() => mockBatch.commit()).thenAnswer((_) async {});

      await RaceDetector.run(5, () => syncService.performFullSync(userId));

      verify(() => mockFirestore.collection(any())).called(greaterThan(0));
    });
  });
}
