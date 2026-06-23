import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:geolocator/geolocator.dart';
import '../repositories/local_repo.dart';
import '../repositories/auth_repo.dart';
import 'notification_service.dart';

class LocationService {
  LocationService({
    required this.localRepo,
    required this.authRepo,
    required this.notificationService,
  });

  final LocalRepo localRepo;
  final AuthRepo authRepo;
  final NotificationService notificationService;

  final StreamController<Position> _positionController = StreamController<Position>.broadcast();
  Stream<Position> get positionStream => _positionController.stream;
  
  final Map<int, DateTime> _notifiedPlaces = {};
  bool _isInitialized = false;

  Future<bool> handlePermission() async {
    // Background Geolocation SDK handles its own permission requests via .start() or .requestPermission()
    // But we still want to ensure location services are enabled.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }
    return true;
  }

  Future<void> init() async {
    if (_isInitialized) return;

    // 1. Listen to events
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      debugPrint('[location] ${location.coords.latitude}, ${location.coords.longitude}');
      
      final position = Position(
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        timestamp: DateTime.parse(location.timestamp),
        accuracy: location.coords.accuracy,
        altitude: location.coords.altitude,
        heading: location.coords.heading,
        speed: location.coords.speed,
        speedAccuracy: location.coords.speedAccuracy,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );

      _positionController.add(position);
      _checkProximity(position);
    });

    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      debugPrint('[providerchange] $event');
    });

    // 2. Configure the SDK
    await bg.BackgroundGeolocation.ready(bg.Config(
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      distanceFilter: 10.0,
      stopOnTerminate: false,
      startOnBoot: true,
      debug: true, // Sounds and notifications for testing
      logLevel: bg.Config.LOG_LEVEL_VERBOSE,
      reset: false,
      enableHeadless: true,
    ));

    _isInitialized = true;
    debugPrint('BackgroundGeolocation initialized');
  }

  void startTracking() async {
    final state = await bg.BackgroundGeolocation.state;
    if (!state.enabled) {
      await bg.BackgroundGeolocation.start();
      debugPrint('BackgroundGeolocation started');
    }
  }

  void stopTracking() {
    bg.BackgroundGeolocation.stop();
  }

  Future<void> _checkProximity(Position position) async {
    final userId = await authRepo.getCurrentUserId();
    if (userId == null) {
      debugPrint('Proximity check failed: User ID is null');
      return;
    }

    final places = await localRepo.getWantToGoPlaces(userId);
    final now = DateTime.now();
    
    debugPrint('Checking proximity for ${places.length} places');

    for (final place in places) {
      if (place.isVisited) continue;

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        place.lat,
        place.lng,
      );
      
      debugPrint('Distance to ${place.name}: ${distance.toStringAsFixed(2)} meters');

      if (distance < 200) {
        final lastNotified = _notifiedPlaces[place.id];
        if (lastNotified == null || now.difference(lastNotified).inHours >= 1) {
          debugPrint('TRIGGERING PROXIMITY NOTIFICATION for ${place.name}');
          _notifiedPlaces[place.id] = now;
          await notificationService.showProximityNotification(
            id: place.id,
            placeName: place.name,
            lat: place.lat,
            lng: place.lng,
          );
        }
      }
    }
  }

  void dispose() {
    _positionController.close();
  }
}
