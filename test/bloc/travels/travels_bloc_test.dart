import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:travel_journal/bloc/travels/travels_bloc.dart';
import 'package:travel_journal/bloc/travels/travels_event.dart';
import 'package:travel_journal/bloc/travels/travels_state.dart';
import 'package:travel_journal/repositories/local_repo.dart';
import 'package:travel_journal/repositories/auth_repo.dart';
import 'package:travel_journal/services/sync_service.dart';
import 'package:travel_journal/database/app_database.dart';
import '../../utils/race_detector.dart';

class MockAuthRepo extends Mock implements AuthRepo {}
class MockSyncService extends Mock implements SyncService {}

void main() {
  late TravelsBloc travelsBloc;
  late LocalRepo localRepo;
  late AppDatabase db;
  late MockAuthRepo mockAuthRepo;
  late MockSyncService mockSyncService;

  setUp(() {
    db = AppDatabase.memory();
    localRepo = LocalRepo(db);
    mockAuthRepo = MockAuthRepo();
    mockSyncService = MockSyncService();
    
    when(() => mockAuthRepo.getCurrentUserId()).thenAnswer((_) async => 'user123');
    when(() => mockSyncService.performFullSync(any())).thenAnswer((_) async {});
    when(() => mockSyncService.syncLocalToCloud(any())).thenAnswer((_) async {});

    travelsBloc = TravelsBloc(
      localRepo: localRepo,
      authRepo: mockAuthRepo,
      syncService: mockSyncService,
    );
  });

  tearDown(() async {
    await travelsBloc.close();
    await db.close();
  });

  group('TravelsBloc Race Condition Tests', () {
    test('Multiple LoadTravelsData events should be handled gracefully', () async {
      for (int i = 0; i < 100; i++) {
        travelsBloc.add(const LoadTravelsData());
      }

      await expectLater(
        travelsBloc.stream,
        emitsThrough(isA<TravelsLoaded>()),
      );
    });

    test('Rapid AddTravelRequested events should maintain consistency', () async {
      final names = ['Trip A', 'Trip B', 'Trip C'];
      
      for (final name in names) {
        travelsBloc.add(AddTravelRequested(name));
      }

      await expectLater(
        travelsBloc.stream,
        emitsThrough(predicate<TravelsState>((state) {
          if (state is TravelsLoaded) {
            return state.travels.length >= 3;
          }
          return false;
        })),
      );

      final travels = await localRepo.getTravels('user123');
      expect(travels.length, 3);
    });
  });
}
