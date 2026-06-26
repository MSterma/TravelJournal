import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:travel_journal/main.dart';
import 'package:travel_journal/locator.dart';
import 'package:travel_journal/database/app_database.dart';
import 'package:travel_journal/repositories/local_repo.dart';
import 'package:travel_journal/repositories/auth_repo.dart';
import 'package:travel_journal/services/notification_service.dart';
import 'package:travel_journal/services/location_service.dart';
import 'package:travel_journal/services/sync_service.dart';
import 'package:travel_journal/l10n/app_localizations.dart';
import 'package:travel_journal/firebase_options.dart';
import 'package:travel_journal/bloc/travels/travels_state.dart'; // Just in case, but let's check
import 'package:travel_journal/utils/constants.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'dart:async';

// Mock Notification Service to capture payloads and simulate clicks
class MockNotificationService extends Mock implements NotificationService {
  final _clickController = StreamController<Map<String, dynamic>>.broadcast();
  @override
  Stream<Map<String, dynamic>> get onNotificationClick =>
      _clickController.stream;

  Function(int, String, double, double, String?, String?)? onShow;

  @override
  Future<void> init({
    String? channelName,
    String? channelDescription,
    bool requestPermissionsOnId = true,
  }) async {
    debugPrint('MockNotificationService: init');
  }

  @override
  Future<void> requestPermissions() async {
    debugPrint('MockNotificationService: requestPermissions');
  }

  @override
  Future<void> showProximityNotification({
    required int id,
    required String placeName,
    required double lat,
    required double lng,
    String? title,
    String? body,
  }) async {
    debugPrint(
      'MockNotificationService: showProximityNotification for $placeName',
    );
    onShow?.call(id, placeName, lat, lng, title, body);
  }

  void simulateClick(Map<String, dynamic> data) {
    _clickController.add(data);
  }
}

// Test Location Service that doesn't start real tracking but allows manual injection
class TestLocationService extends LocationService {
  TestLocationService({
    required super.localRepo,
    required super.authRepo,
    required super.notificationService,
  });

  @override
  Future<bool> handlePermission() async => true;

  @override
  void startTracking() {
    debugPrint(
      'TestLocationService: startTracking (mocked - no real geolocator)',
    );
  }

  @override
  Future<Position> getCurrentPosition() async {
    return FakePosition(latitude: 52.4064, longitude: 16.9252);
  }
}

class FakePosition extends Fake implements Position {
  FakePosition({required this.latitude, required this.longitude})
    : timestamp = DateTime.now();

  @override
  final double latitude;
  @override
  final double longitude;
  @override
  final DateTime timestamp;
  @override
  final double accuracy = 0;
  @override
  final double altitude = 0;
  @override
  final double heading = 0;
  @override
  final double speed = 0;
  @override
  final double speedAccuracy = 0;
  @override
  final double altitudeAccuracy = 0;
  @override
  final double headingAccuracy = 0;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('E2E Real Infrastructure Proximity Test', () {
    setUpAll(() async {
      debugPrint('Global Setup...');
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint('Warning: .env not found, using .env.example if exists');
        try {
          await dotenv.load(fileName: ".env.example");
        } catch (_) {}
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      registerFallbackValue(FakePosition(latitude: 0, longitude: 0));
    });

    setUp(() async {
      debugPrint('Resetting Locator...');
      if (locator.isRegistered<AppDatabase>()) {
        await locator<AppDatabase>().close();
      }
      await locator.reset();
      setupLocator();

      locator.unregister<AppDatabase>();
      locator.registerSingleton<AppDatabase>(AppDatabase.memory());

      locator.unregister<LocalRepo>();
      locator.registerSingleton<LocalRepo>(LocalRepo(locator<AppDatabase>()));

      final notificationService = MockNotificationService();
      final locationService = TestLocationService(
        localRepo: locator<LocalRepo>(),
        authRepo: locator<AuthRepo>(),
        notificationService: notificationService,
      );

      locator.unregister<NotificationService>();
      locator.registerSingleton<NotificationService>(notificationService);

      locator.unregister<LocationService>();
      locator.registerSingleton<LocationService>(locationService);
    });

    tearDown(() async {
      debugPrint('Tear Down: Cleaning up data...');
      try {
        final authRepo = locator<AuthRepo>();
        final userId = await authRepo.getCurrentUserId();
        if (userId != null) {
          final localRepo = locator<LocalRepo>();
          final syncService = locator<SyncService>();

          await syncService.clearCloudData(userId);
          await localRepo.clearUserData(userId);

          await authRepo.firebaseAuth.currentUser?.delete();

          await authRepo.signOut();
        }
      } catch (e) {
        debugPrint('Error during tearDown: $e');
      }

      if (locator.isRegistered<AppDatabase>()) {
        await locator<AppDatabase>().close();
      }
    });

    testWidgets(
      'Full flow: Register -> Add WantToGo -> Move -> Notify -> Click -> Add Note',
      (tester) async {
        await tester.pumpWidget(const MyApp());
        await tester.pumpAndSettle();

        // 1. Registration Flow
        debugPrint('Navigating to Registration...');
        final l10n = await tester.runAsync(() async {
          return lookupAppLocalizations(
            WidgetsBinding.instance.platformDispatcher.locale,
          );
        });

        final noAccountBtn = find.text(l10n!.noAccount);
        await tester.tap(noAccountBtn);
        await tester.pumpAndSettle();

        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final email = 'test_e2e_$timestamp@example.com';
        final password = 'password123';

        await tester.enterText(
          find.widgetWithText(TextField, l10n.email),
          email,
        );
        await tester.enterText(
          find.widgetWithText(TextField, l10n.password),
          password,
        );

        debugPrint('Creating account: $email');
        await tester.tap(find.text(l10n.createAccount));

        await tester.pumpAndSettle(const Duration(seconds: 5));

        // 2. Navigate to Travels Tab
        debugPrint('Navigating to Travels tab...');
        final travelsTab = find.byIcon(Icons.timeline).last;
        await tester.tap(travelsTab);
        await tester.pumpAndSettle();

        final allowBtn = find.text('While using the app');
        if (tester.any(allowBtn)) {
          await tester.tap(allowBtn);
          await tester.pumpAndSettle();
        }
        // 3. Add a WantToGo place
        debugPrint('Adding WantToGo place...');
        final addWantToGoBtn = find.byIcon(Icons.explore).first;
        await tester.tap(addWantToGoBtn);
        await tester.pumpAndSettle();

        final destName = 'E2E Destination $timestamp';
        await tester.enterText(find.byType(TextField), destName);
        await tester.tap(find.text(l10n.save.toUpperCase()));
        await tester.pumpAndSettle();

        final localRepo = locator<LocalRepo>();
        final authRepo = locator<AuthRepo>();
        final userId = await authRepo.getCurrentUserId();
        final places = await localRepo.getWantToGoPlaces(userId!);
        final dest = places.firstWhere((p) => p.name == destName);
        debugPrint('Destination saved at: ${dest.lat}, ${dest.lng}');

        // 4. Simulate Movement
        final notificationService =
            locator<NotificationService>() as MockNotificationService;
        final locationService = locator<LocationService>();

        bool notificationTriggered = false;
        Map<String, dynamic>? capturedPayload;
        notificationService.onShow = (id, name, lat, lng, t, b) {
          notificationTriggered = true;
          capturedPayload = {
            'type': 'proximity_note',
            'placeName': name,
            'lat': lat,
            'lng': lng,
          };
        };

        debugPrint('Simulating movement towards destination...');
        final testPosition = FakePosition(
          latitude: dest.lat + 0.0001,
          longitude: dest.lng + 0.0001,
        );

        // Verify distance calculation logic explicitly
        final calculatedDistance = locationService.calculateDistanceToPlace(
          testPosition,
          dest,
        );
        debugPrint('Calculated distance to destination: $calculatedDistance');
        expect(
          calculatedDistance,
          lessThan(AppConstants.proximityDistanceThreshold),
        );

        // Final move into threshold
        await locationService.processPosition(testPosition);
        await tester.pumpAndSettle();

        expect(notificationTriggered, isTrue);
        debugPrint('Notification triggered!');

        // 5. Click Notification
        debugPrint('Simulating notification click...');
        notificationService.simulateClick(capturedPayload!);
        await tester.pumpAndSettle();

        // 6. Verify Note Form and Save
        debugPrint('Saving Note...');
        expect(find.text(l10n.newNote), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextField, l10n.nameRequired),
          'E2E Real Note',
        );
        await tester.tap(find.text(l10n.save.toUpperCase()));
        await tester.pumpAndSettle();

        // 7. Final Verification
        final notes = await localRepo.getAllNotes(userId);
        expect(notes.any((n) => n.name == 'E2E Real Note'), isTrue);
        debugPrint('Test Successful!');
      },
    );
  });
}
