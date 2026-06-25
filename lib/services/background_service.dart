import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:geolocator/geolocator.dart';
import '../database/app_database.dart';
import '../repositories/local_repo.dart';
import 'notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repo.dart';
import '../firebase_options.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> initializeBackgroundService(AppLocalizations l10n) async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'proximity_channel',
      initialNotificationTitle: l10n.bgTrackingTitle,
      initialNotificationContent: l10n.bgTrackingContent,
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dotenv in background isolate as well, because FirebaseOptions depends on it
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('BG Isolate: Failed to load .env: $e');
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final db = AppDatabase();
  final localRepo = LocalRepo(db);
  final authRepo = AuthRepo(FirebaseAuth.instance);
  final notificationService = NotificationService();
  
  final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
  await notificationService.init(
    channelName: l10n.proximityAlertsChannelName,
    channelDescription: l10n.proximityAlertsChannelDesc,
    requestPermissionsOnId: false,
  );

  final Map<int, DateTime> notifiedPlaces = {};

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).listen((Position position) async {
    debugPrint('BG Isolate: Location Update: ${position.latitude}, ${position.longitude}');

    service.invoke('update', {
      'latitude': position.latitude,
      'longitude': position.longitude,
    });

    final userId = await authRepo.getCurrentUserId();
    if (userId == null) return;

    final places = await localRepo.getWantToGoPlaces(userId);
    final now = DateTime.now();

    for (final place in places) {
      if (place.isVisited) continue;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        place.lat,
        place.lng,
      );

      if (distance < 200) {
        final lastNotified = notifiedPlaces[place.id];
        if (lastNotified == null || now.difference(lastNotified).inHours >= 1) {
          notifiedPlaces[place.id] = now;
          await notificationService.showProximityNotification(
            id: place.id,
            placeName: place.name,
            lat: place.lat,
            lng: place.lng,
            title: l10n.proximityNotificationTitle,
            body: l10n.proximityNotificationBody(place.name),
          );
        }
      }
    }
  });
}
