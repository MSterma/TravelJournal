import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../database/app_database.dart';
import '../repositories/local_repo.dart';
import '../repositories/auth_repo.dart';
import '../utils/constants.dart';
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

  final StreamController<Position> _positionController =
      StreamController<Position>.broadcast();
  Stream<Position> get positionStream => _positionController.stream;

  final StreamController<Position> mapCenterController =
      StreamController<Position>.broadcast();

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

    Geolocator.getCurrentPosition().then((pos) {
      _positionController.add(pos);
    });

    final LocationSettings locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: AppConstants.locationDistanceFilter,
    );

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            processPosition(position);
          },
        );

    _isTracking = true;
  }

  Future<void> processPosition(Position position) async {
    _positionController.add(position);
    await _checkProximity(position);
  }

  Future<Position> getCurrentPosition() async {
    return await Geolocator.getCurrentPosition();
  }

  void stopTracking() {
    _positionSubscription?.cancel();
    _isTracking = false;
  }

  /// Calculates the distance between the current position and a [WantToGoPlace].
  double calculateDistanceToPlace(Position position, WantToGoPlace place) {
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      place.lat,
      place.lng,
    );
  }

  /// Formats the distance to a place in a user-friendly way.
  String formatDistance(double distanceInMeters, AppLocalizations l10n) {
    if (distanceInMeters < 1000) {
      return l10n.distanceM(distanceInMeters.round());
    } else {
      final int km = distanceInMeters ~/ 1000;
      final int m = (distanceInMeters % 1000).round();
      return l10n.distanceKm(km, m);
    }
  }

  Future<void> _checkProximity(Position position) async {
    final userId = await authRepo.getCurrentUserId();
    if (userId == null) return;

    final places = await localRepo.getWantToGoPlaces(userId);
    final now = DateTime.now();

    for (final place in places) {
      if (place.isVisited) continue;

      final distance = calculateDistanceToPlace(position, place);

      if (distance < AppConstants.proximityDistanceThreshold) {
        final lastNotified = _notifiedPlaces[place.id];
        if (lastNotified == null ||
            now.difference(lastNotified).inHours >=
                AppConstants.notificationIntervalHours) {
          _notifiedPlaces[place.id] = now;
          final l10n = lookupAppLocalizations(
            PlatformDispatcher.instance.locale,
          );
          await notificationService.showProximityNotification(
            id: place.id,
            placeName: place.name,
            lat: place.lat,
            lng: place.lng,
            title: l10n.proximityNotificationTitle,
            body: l10n.proximityNotificationBody(
              place.name,
              formatDistance(distance, l10n),
            ),
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
