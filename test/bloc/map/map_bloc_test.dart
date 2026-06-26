import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travel_journal/bloc/map/map_bloc.dart';
import 'package:travel_journal/bloc/map/map_event.dart';
import 'package:travel_journal/bloc/map/map_state.dart';
import 'package:travel_journal/repositories/local_repo.dart';
import 'package:travel_journal/repositories/auth_repo.dart';
import 'package:travel_journal/database/app_database.dart';

class MockAuthRepo extends Mock implements AuthRepo {}

void main() {
  late MapBloc mapBloc;
  late LocalRepo localRepo;
  late AppDatabase db;
  late MockAuthRepo mockAuthRepo;

  setUp(() {
    db = AppDatabase.memory();
    localRepo = LocalRepo(db);
    mockAuthRepo = MockAuthRepo();
    
    when(() => mockAuthRepo.getCurrentUserId()).thenAnswer((_) async => 'user123');

    mapBloc = MapBloc(localRepo, mockAuthRepo);
  });

  tearDown(() async {
    await mapBloc.close();
    await db.close();
  });

  group('MapBloc Race Condition Tests', () {
    test('Sequential LoadMarkers should update state correctly', () async {
      mapBloc.add(const LoadMarkers());
      mapBloc.add(const LoadMarkers());
      mapBloc.add(const LoadMarkers());

      await expectLater(
        mapBloc.stream,
        emitsThrough(isA<MapLoaded>()),
      );
    });
  });
}
