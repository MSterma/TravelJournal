import 'dart:io';
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
import '../widgets/universal_form_modal.dart';
import '../widgets/note_form_modal.dart';
import '../widgets/photo_viewer.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';

import '../widgets/image_placeholder.dart';

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

  @override
  void initState() {
    super.initState();
    _initLocationTracking();
    _getCurrentLocation();
  }
  Future<void> _initLocationTracking() async {
    final locationService = locator<LocationService>();

    locationService.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

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
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
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
    locator<NotificationService>().showProximityNotification(
      id: 999,
      placeName: "Test Place",
      lat: _mapController.camera.center.latitude,
      lng: _mapController.camera.center.longitude,
      title: l10n.proximityNotificationTitle,
      body: l10n.proximityNotificationBody("Test Place"),
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
                      final isPlaceholder = path == '__PLACEHOLDER__';
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
      body: BlocConsumer<TravelsBloc, TravelsState>(
        listener: (context, state) {
          if (state is TravelsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.failure.message),
                  backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is TravelsLoading) {
            return const LoadingIndicator();
          }

          if (state is TravelsError) {
            return ErrorView(
              message: state.failure.message,
              onRetry: () =>
                  context.read<TravelsBloc>().add(const TravelsEvent.loadData()),
            );
          }

          if (state is TravelsLoaded) {
            return Stack(
              children: [
                _buildMap(state),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 48.0),
                    child: Icon(Icons.add_location_alt,
                        color: Colors.green, size: 48),
                  ),
                ),
                Positioned(
                  top: 60,
                  left: 16,
                  child: Container(
                    decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(25)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () => _showAddNote(state.selectedTravelId)),
                        const VerticalDivider(width: 1, color: Colors.white24),
                        IconButton(
                            icon: const Icon(Icons.explore, color: Colors.white),
                            onPressed: () => _showAddWantToGo(l10n)),
                        const VerticalDivider(width: 1, color: Colors.white24),
                        IconButton(
                            icon: const Icon(Icons.notifications_active, color: Colors.white),
                            onPressed: _testNotification),
                      ],
                    ),
                  ),
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
                _buildDraggableSheet(state, l10n),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMap(TravelsLoaded state) {
    final l10n = AppLocalizations.of(context)!;
    final selectedTravelNotes = state.allNotes
        .where((n) => n.travelId == state.selectedTravelId)
        .toList();

    return FlutterMap(
      mapController: _mapController,
      options: const MapOptions(
        initialCenter: LatLng(52.4064, 16.9252),
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.travelJournal',
        ),
        PolylineLayer(
          polylines: [
            if (state.selectedTravelId != null && selectedTravelNotes.length > 1)
              Polyline(
                points: selectedTravelNotes
                    .map((n) => LatLng(n.lat, n.lng))
                    .toList(),
                color: Colors.red,
                strokeWidth: 3.0,
              ),
          ],
        ),
        MarkerLayer(
          markers: [
            ...state.allNotes.map((n) {
              final isSelectedGroup =
                  state.selectedTravelId != null && n.travelId == state.selectedTravelId;
              return Marker(
                point: LatLng(n.lat, n.lng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () {
                    context
                        .read<TravelsBloc>()
                        .add(TravelsEvent.selectTravel(n.travelId));
                    if (_sheetController.isAttached) {
                      _sheetController.animateTo(0.6,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut);
                    }
                  },
                  child: Icon(
                    Icons.location_on,
                    color: isSelectedGroup ? Colors.red : Colors.blue,
                    size: 40,
                  ),
                ),
              );
            }),
            ...state.wantToGoPlaces.map((p) {
              return Marker(
                point: LatLng(p.lat, p.lng),
                width: 40,
                height: 40,
                child: GestureDetector(
                  onTap: () => _showPlaceDetails(p, l10n),
                  child: Icon(
                    p.isVisited ? Icons.check_circle : Icons.explore,
                    color: p.isVisited ? Colors.grey : Colors.orange,
                    size: 30,
                  ),
                ),
              );
            }),
            if (_currentPosition != null)
              Marker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.green,
                  size: 30,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDraggableSheet(TravelsLoaded state, AppLocalizations l10n) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.4,
      minChildSize: 0.1,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.travelTimeline,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const Icon(Icons.more_vert),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip(l10n.all, null, state.selectedTravelId),
                    ...state.travels.map(
                        (t) => _buildChip(t.travelName, t.id, state.selectedTravelId)),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                          label: const Text('+'),
                          onPressed: () => _showAddTravel(l10n)),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (state.selectedTravelId == null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(l10n.selectTravelPrompt,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey)),
                )
              else if (state.timelineNotes.isEmpty)
                Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(l10n.noEntriesInTravel))
              else
                Column(
                  children: state.timelineNotes.map((n) {
                    return _buildTimelineItem(
                        n, state.notePhotos[n.id] ?? [], state.allTimelinePhotos, state.travels, l10n);
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip(String label, int? travelId, int? selectedTravelId) {
    final isSelected = selectedTravelId == travelId;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          context.read<TravelsBloc>().add(TravelsEvent.selectTravel(travelId));
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildTimelineItem(Note note, List<String> photos, List<String> allTimelinePhotos, List<Travel> travels, AppLocalizations l10n) {
    final dateStr = "${note.date.day}-${note.date.month}-${note.date.year}";
    final travelName = travels.where((t) => t.id == note.travelId).firstOrNull?.travelName ?? l10n.none;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 2, height: 16, color: Colors.blue),
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.blue, shape: BoxShape.circle)),
              Container(
                  width: 2, height: photos.isNotEmpty ? 130 : 90, color: Colors.blue),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("$dateStr: ${note.name}",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (photos.isNotEmpty)
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(top: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (ctx, i) {
                      final path = photos[i];
                      final isPlaceholder = path == '__PLACEHOLDER__';
                      final exists = !isPlaceholder && File(path).existsSync();

                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            final globalIndex = allTimelinePhotos.indexOf(path);
                            PhotoViewer.show(context,
                                photos: allTimelinePhotos,
                                initialIndex:
                                    globalIndex != -1 ? globalIndex : 0,
                                source: PhotoSource.file);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: exists
                                ? Image.file(File(path),
                                    width: 60, height: 60, fit: BoxFit.cover)
                                : const ImagePlaceholder(
                                    width: 60, height: 60),
                          ),
                        ),
                      );
                    },
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  child: TextButton(
                    style: TextButton.styleFrom(
                        padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                    onPressed: () =>
                        _showNoteDetails(note, travelName, photos, l10n),
                    child: Text(l10n.details),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
