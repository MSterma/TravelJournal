import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../l10n/app_localizations.dart';
import '../../locator.dart';
import '../../repositories/local_repo.dart';
import '../../repositories/auth_repo.dart';
import '../../database/app_database.dart';
import '../widgets/universal_form_modal.dart';
import '../widgets/note_form_modal.dart';
import '../widgets/photo_viewer.dart';

class TravelsScreen extends StatefulWidget {
  const TravelsScreen({super.key});

  @override
  State<TravelsScreen> createState() => _TravelsScreenState();
}

class _TravelsScreenState extends State<TravelsScreen> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  int? _selectedTravelId;

  List<Travel> _travels = [];
  List<Note> _allNotes = [];
  List<Note> _timelineNotes = [];
  Map<int, List<String>> _notePhotos = {};
  List<String> _allTimelinePhotos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await locator<AuthRepo>().getCurrentUserId();
    if (userId == null) return;

    final travels = await locator<LocalRepo>().getTravels(userId);
    final allNotes = await locator<LocalRepo>().getAllNotes(userId);

    final timelineNotes = _selectedTravelId == null
        ? <Note>[]
        : allNotes.where((n) => n.travelId == _selectedTravelId).toList();

    final photosMap = <int, List<String>>{};
    final allPhotos = <String>[];

    for (final n in timelineNotes) {
      final p = await locator<LocalRepo>().getNotePhotos(n.id);
      photosMap[n.id] = p;
      allPhotos.addAll(p);
    }

    if (mounted) {
      setState(() {
        _travels = travels;
        _allNotes = allNotes;
        _timelineNotes = timelineNotes;
        _notePhotos = photosMap;
        _allTimelinePhotos = allPhotos;
        _isLoading = false;
      });
    }
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
  }

  void _showAddTravel(AppLocalizations l10n) {
    UniversalFormModal.show(
      context,
      title: l10n.newTravel,
      label: l10n.name,
      onSubmit: (val) async {
        final userId = await locator<AuthRepo>().getCurrentUserId();
        if (userId != null) {
          await locator<LocalRepo>().addTravel(val, userId);
          _loadData();
        }
      },
    );
  }

  void _showAddNote() async {
    final userId = await locator<AuthRepo>().getCurrentUserId();
    if (userId != null && context.mounted) {
      final center = _mapController.camera.center;

      NoteFormModal.show(
        context,
        userId: userId,
        lat: center.latitude,
        lng: center.longitude,
        initialTravelId: _selectedTravelId,
        onSuccess: _loadData,
      );
    }
  }

  void _showNoteDetails(Note note, String travelName, List<String> photos, AppLocalizations l10n) {
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
                  width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Text(note.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('${l10n.travelLabel}$travelName', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              Text(note.userNote ?? l10n.noNoteContent),
              const SizedBox(height: 16),
              if (photos.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => PhotoViewer.show(context, photos: photos, initialIndex: i, source: PhotoSource.file),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(photos[i]), width: 100, height: 100, fit: BoxFit.cover),
                        ),
                      ),
                    ),
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
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
                  if (_selectedTravelId != null && _allNotes.where((n) => n.travelId == _selectedTravelId).length > 1)
                    Polyline(
                      points: _allNotes
                          .where((n) => n.travelId == _selectedTravelId)
                          .map((n) => LatLng(n.lat, n.lng))
                          .toList(),
                      color: Colors.red,
                      strokeWidth: 3.0,
                    ),
                ],
              ),
              MarkerLayer(
                markers: _allNotes.map((n) {
                  final isSelectedGroup = _selectedTravelId != null && n.travelId == _selectedTravelId;
                  return Marker(
                    point: LatLng(n.lat, n.lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTravelId = n.travelId;
                          _isLoading = true;
                        });
                        _loadData();
                        if (_sheetController.isAttached) {
                          _sheetController.animateTo(0.6, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        }
                      },
                      child: Icon(
                        Icons.location_on,
                        color: isSelectedGroup ? Colors.red : Colors.blue,
                        size: 40,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 48.0),
              child: Icon(Icons.add_location_alt, color: Colors.green, size: 48),
            ),
          ),

          Positioned(
            top: 60,
            left: 16,
            child: Container(
              decoration: BoxDecoration(color: Colors.blue[700], borderRadius: BorderRadius.circular(25)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.add, color: Colors.white), onPressed: _showAddNote),
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

          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.4,
            minChildSize: 0.1,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  children: [
                    Center(
                      child: Container(
                        width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.grey[500], borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l10n.travelTimeline, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const Icon(Icons.more_vert),
                      ],
                    ),
                    const SizedBox(height: 16),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildChip(l10n.all, null),
                          ..._travels.map((t) => _buildChip(t.travelName, t.id)),
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ActionChip(label: const Text('+'), onPressed: () => _showAddTravel(l10n)),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_selectedTravelId == null)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(l10n.selectTravelPrompt, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                      )
                    else if (_timelineNotes.isEmpty)
                      Padding(padding: const EdgeInsets.all(16.0), child: Text(l10n.noEntriesInTravel))
                    else
                      Column(
                        children: _timelineNotes.map((n) {
                          return _buildTimelineItem(n, _notePhotos[n.id] ?? [], l10n);
                        }).toList(),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int? travelId) {
    final isSelected = _selectedTravelId == travelId;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedTravelId = travelId;
            _isLoading = true;
          });
          _loadData();
        },
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildTimelineItem(Note note, List<String> photos, AppLocalizations l10n) {
    final dateStr = "${note.date.day}-${note.date.month}-${note.date.year}";
    final travelName = _travels.where((t) => t.id == note.travelId).firstOrNull?.travelName ?? l10n.none;

    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 2, height: 16, color: Colors.blue),
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle)),
              Container(width: 2, height: photos.isNotEmpty ? 130 : 90, color: Colors.blue),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text("$dateStr: ${note.name}", style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                if (photos.isNotEmpty)
                  Container(
                    height: 60,
                    margin: const EdgeInsets.only(top: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (ctx, i) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            final globalIndex = _allTimelinePhotos.indexOf(photos[i]);
                            PhotoViewer.show(context, photos: _allTimelinePhotos, initialIndex: globalIndex != -1 ? globalIndex : 0, source: PhotoSource.file);
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(File(photos[i]), width: 60, height: 60, fit: BoxFit.cover),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 30,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
                    onPressed: () => _showNoteDetails(note, travelName, photos, l10n),
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