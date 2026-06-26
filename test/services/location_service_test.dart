import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:travel_journal/services/location_service.dart';
import 'package:travel_journal/repositories/local_repo.dart';
import 'package:travel_journal/repositories/auth_repo.dart';
import 'package:travel_journal/services/notification_service.dart';
import 'package:travel_journal/database/app_database.dart';
import '../utils/race_detector.dart';

class MockAuthRepo extends Mock implements AuthRepo {}

class MockNotificationService extends Mock implements NotificationService {}

class FakePosition extends Fake implements Position {
  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final DateTime timestamp;

  FakePosition({required this.latitude, required this.longitude})
    : timestamp = DateTime.now();
}

void main() {
  late LocationService locationService;
  late LocalRepo localRepo;
  late AppDatabase db;
  late MockAuthRepo mockAuthRepo;
  late MockNotificationService mockNotificationService;

  setUp(() {
    db = AppDatabase.memory();
    localRepo = LocalRepo(db);
    mockAuthRepo = MockAuthRepo();
    mockNotificationService = MockNotificationService();
    locationService = LocationService(
      localRepo: localRepo,
      authRepo: mockAuthRepo,
      notificationService: mockNotificationService,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('LocationService Race Condition Tests', () {
    test(
      'processPosition should debounce notifications correctly even with rapid updates',
      () async {
        const userId = 'user123';
        when(
          () => mockAuthRepo.getCurrentUserId(),
        ).thenAnswer((_) async => userId);
        when(
          () => mockNotificationService.showProximityNotification(
            id: any(named: 'id'),
            placeName: any(named: 'placeName'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async {});

        await localRepo.addWantToGoPlace('Target Place', 10.0, 10.0, userId);

        final positionNear = FakePosition(
          latitude: 10.0001,
          longitude: 10.0001,
        );

        await RaceDetector.run(
          10,
          () => locationService.processPosition(positionNear),
        );

        verify(
          () => mockNotificationService.showProximityNotification(
            id: any(named: 'id'),
            placeName: any(named: 'placeName'),
            lat: any(named: 'lat'),
            lng: any(named: 'lng'),
            title: any(named: 'title'),
            body: any(named: 'body'),
          ),
        ).called(1);
      },
    );
  });
}
