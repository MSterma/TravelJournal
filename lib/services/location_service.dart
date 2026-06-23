import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../repositories/local_repo.dart';
import '../repositories/auth_repo.dart';
import 'notification_service.dart';
import '../l10n/app_localizations.dart';

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

  final StreamController<Position> mapCenterController = StreamController<Position>.broadcast();

  StreamSubscription<Position>? _positionSubscription;
  final Map<int, DateTime> _notifiedPlaces = {};
  bool _isTracking = false;

  Future<bool> handlePermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  Future<void> init() async {
    await handlePermission();
  }

  void startTracking() async {
    if (_isTracking) return;

    bool hasPermission = await handlePermission();
    if (!hasPermission) return;

    // Szybki pierwszy odczyt
    Geolocator.getCurrentPosition().then((pos) {
      _positionController.add(pos);
    });

    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Zmienić 100 na 10 metrów
    );

    _positionSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
            (Position position) {
          _positionController.add(position);
          _checkProximity(position);
        }
    );

    _isTracking = true;
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _isTracking = false;
  }

  Future<void> _checkProximity(Position position) async {
    final userId = await authRepo.getCurrentUserId();
    if (userId == null) return;

    final places = await localRepo.getWantToGoPlaces(userId);
    final now = DateTime.now();

    for (final place in places) {
      if (place.isVisited) continue;

      final distance = Geolocator.distanceBetween(
        position.latitude, position.longitude, place.lat, place.lng,
      );

      if (distance < 200) {
        final lastNotified = _notifiedPlaces[place.id];
        if (lastNotified == null || now.difference(lastNotified).inHours >= 1) {
          _notifiedPlaces[place.id] = now;
          final l10n = lookupAppLocalizations(PlatformDispatcher.instance.locale);
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
  }

  void dispose() {
    _positionSubscription?.cancel();
    _positionController.close();
    mapCenterController.close();
  }
}