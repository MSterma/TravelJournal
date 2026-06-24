import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../../bloc/travels/travels_bloc.dart';
import '../../../bloc/travels/travels_state.dart';
import '../../../database/app_database.dart';

class TravelsMap extends StatelessWidget {
  const TravelsMap({
    super.key,
    required this.mapController,
    required this.currentPosition,
    required this.onMarkerTap,
    required this.onPlaceTap,
  });

  final MapController mapController;
  final Position? currentPosition;
  final Function(Note) onMarkerTap;
  final Function(WantToGoPlace) onPlaceTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TravelsBloc, TravelsState>(
      buildWhen: (prev, curr) {
        if (prev is! TravelsLoaded || curr is! TravelsLoaded) return true;
        return prev.allNotes != curr.allNotes ||
            prev.wantToGoPlaces != curr.wantToGoPlaces ||
            prev.selectedTravelId != curr.selectedTravelId;
      },
      builder: (context, state) {
        if (state is! TravelsLoaded) return const SizedBox.shrink();

        final selectedTravelNotes = state.allNotes
            .where((n) => n.travelId == state.selectedTravelId)
            .toList();

        return FlutterMap(
          mapController: mapController,
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
                if (state.selectedTravelId != null &&
                    selectedTravelNotes.length > 1)
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
                  final isSelectedGroup = state.selectedTravelId != null &&
                      n.travelId == state.selectedTravelId;
                  return Marker(
                    point: LatLng(n.lat, n.lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => onMarkerTap(n),
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
                      onTap: () => onPlaceTap(p),
                      child: Icon(
                        p.isVisited ? Icons.check_circle : Icons.explore,
                        color: p.isVisited ? Colors.grey : Colors.orange,
                        size: 30,
                      ),
                    ),
                  );
                }),
                if (currentPosition != null)
                  Marker(
                    point: LatLng(
                        currentPosition!.latitude, currentPosition!.longitude),
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
      },
    );
  }
}
