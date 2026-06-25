import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
import '../../locator.dart';
import '../../repositories/auth_repo.dart';
import '../../database/app_database.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../bloc/travels/travels_bloc.dart';
import '../../bloc/travels/travels_event.dart';
import '../../bloc/travels/travels_state.dart';
import '../../utils/constants.dart';
import '../widgets/modals/universal_form_modal.dart';
import '../widgets/modals/note_form_modal.dart';
import '../widgets/common/photo_viewer.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/image_placeholder.dart';

import '../widgets/travels/travels_map.dart';
import '../widgets/travels/travels_controls.dart';
import '../widgets/travels/travels_draggable_sheet.dart';

class TravelsScreen extends StatefulWidget {
  const TravelsScreen({super.key});

  @override
  State<TravelsScreen> createState() => _TravelsScreenState();
}

class _TravelsScreenState extends State<TravelsScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  StreamSubscription<Position>? _mapCenterSubscription;

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _mapCenterSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initLocationTracking() async {
    final locationService = locator<LocationService>();

    _positionSubscription = locationService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    _mapCenterSubscription =
        locationService.mapCenterController.stream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
        _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    _mapController.move(LatLng(position.latitude, position.longitude), 15.0);

    setState(() {
      _currentPosition = position;
    });
  }

  void _showPlaceDetails(WantToGoPlace place, AppLocalizations l10n) {
    final locationService = locator<LocationService>();
    String? distanceText;
    if (_currentPosition != null) {
      final distance =
          locationService.calculateDistanceToPlace(_currentPosition!, place);
      distanceText = locationService.formatDistance(distance, l10n);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(place.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            if (distanceText != null) ...[
              const SizedBox(height: 4),
              Text(distanceText,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<TravelsBloc>().add(
                        TravelsEvent.togglePlaceVisited(
                          id: place.id,
                          isVisited: !place.isVisited,
                        ),
                      );
                  Navigator.pop(ctx);
                },
                icon: Icon(place.isVisited ? Icons.undo : Icons.check_circle),
                label: Text(place.isVisited
                    ? l10n.unmarkAsVisited
                    : l10n.markAsVisited),
                style: ElevatedButton.styleFrom(
                  backgroundColor: place.isVisited ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _testNotification() {
    final l10n = AppLocalizations.of(context)!;
    final locationService = locator<LocationService>();
    locator<NotificationService>().showProximityNotification(
      id: 999,
      placeName: "Test Place",
      lat: _mapController.camera.center.latitude,
      lng: _mapController.camera.center.longitude,
      title: l10n.proximityNotificationTitle,
      body: l10n.proximityNotificationBody(
          "Test Place", locationService.formatDistance(0, l10n)),
    );
  }

  void _showAddTravel(AppLocalizations l10n) {
    UniversalFormModal.show(
      context,
      title: l10n.newTravel,
      label: l10n.name,
      onSubmit: (val) {
        context.read<TravelsBloc>().add(TravelsEvent.addTravel(val));
      },
    );
  }

  void _showAddNote(int? selectedTravelId) async {
    final authRepo = locator<AuthRepo>();
    final userId = await authRepo.getCurrentUserId();
    if (userId != null && mounted) {
      final center = _mapController.camera.center;

      NoteFormModal.show(
        context,
        userId: userId,
        lat: center.latitude,
        lng: center.longitude,
        initialTravelId: selectedTravelId,
        onSuccess: () {
          if (mounted) {
            context.read<TravelsBloc>().add(const TravelsEvent.loadData());
          }
        },
      );
    }
  }

  void _showAddWantToGo(AppLocalizations l10n) {
    final center = _mapController.camera.center;
    UniversalFormModal.show(
      context,
      title: l10n.wantToGo,
      label: l10n.placeName,
      onSubmit: (val) {
        context.read<TravelsBloc>().add(TravelsEvent.addWantToGoPlace(
              name: val,
              lat: center.latitude,
              lng: center.longitude,
            ));
      },
    );
  }

  void _showNoteDetails(Note note, String travelName, List<String> photos,
      AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey[500],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Text(note.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${l10n.travelLabel}$travelName',
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Text(note.userNote ?? l10n.noNoteContent),
              const SizedBox(height: 16),
              if (photos.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    itemBuilder: (ctx, i) {
                      final path = photos[i];
                      final isPlaceholder =
                          path == AppConstants.photoPlaceholder;
                      final exists = !isPlaceholder && File(path).existsSync();

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => PhotoViewer.show(context,
                              photos: photos,
                              initialIndex: i,
                              source: PhotoSource.file),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: exists
                                ? Image.file(File(path),
                                    width: 100, height: 100, fit: BoxFit.cover)
                                : const ImagePlaceholder(
                                    width: 100, height: 100),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: BlocListener<TravelsBloc, TravelsState>(
        listener: (context, state) {
          if (state is TravelsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.failure.message),
                  backgroundColor: Colors.red),
            );
          }
        },
        child: BlocBuilder<TravelsBloc, TravelsState>(
          buildWhen: (prev, curr) {
            return prev.runtimeType != curr.runtimeType;
          },
          builder: (context, state) {
            if (state is TravelsLoading) {
              return const LoadingIndicator();
            }

            if (state is TravelsError) {
              return ErrorView(
                message: state.failure.message,
                onRetry: () => context
                    .read<TravelsBloc>()
                    .add(const TravelsEvent.loadData()),
              );
            }

            if (state is TravelsLoaded) {
              return Stack(
                children: [
                  TravelsMap(
                    mapController: _mapController,
                    currentPosition: _currentPosition,
                    onMarkerTap: (n) {
                      context
                          .read<TravelsBloc>()
                          .add(TravelsEvent.selectTravel(n.travelId));
                      if (_sheetController.isAttached) {
                        _sheetController.animateTo(0.6,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut);
                      }
                    },
                    onPlaceTap: (p) => _showPlaceDetails(p, l10n),
                    locationService: locator<LocationService>(),
                  ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 48.0),
                      child: Icon(Icons.add_location_alt,
                          color: Colors.green, size: 48),
                    ),
                  ),
                  TravelsControls(
                    onAddNote: () => _showAddNote(state.selectedTravelId),
                    onAddWantToGo: () => _showAddWantToGo(l10n),
                    onTestNotification: _testNotification,
                  ),
                  Positioned(
                    bottom: MediaQuery.of(context).size.height * 0.45,
                    right: 16,
                    child: FloatingActionButton(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      mini: true,
                      onPressed: _getCurrentLocation,
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                  TravelsDraggableSheet(
                    sheetController: _sheetController,
                    onAddTravel: () => _showAddTravel(l10n),
                    onShowNoteDetails: _showNoteDetails,
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
