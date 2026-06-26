import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../locator.dart';
import '../../repositories/local_repo.dart';
import '../../repositories/auth_repo.dart';
import '../../repositories/country_repo.dart';
import '../../bloc/country_details/country_details_bloc.dart';
import '../../bloc/country_details/country_details_event.dart';
import '../../bloc/map/map_bloc.dart';
import '../../bloc/map/map_event.dart';
import '../../bloc/map/map_state.dart';
import '../../l10n/app_localizations.dart';
import '../../services/sync_service.dart';
import '../countries/detail_screen.dart';
import '../widgets/common/loading_indicator.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocProvider(
      create: (context) =>
          MapBloc(locator<LocalRepo>(), locator<AuthRepo>())
            ..add(const LoadMarkers()),
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.visitedPlaces)),
        body: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            if (state is MapLoading) {
              return const LoadingIndicator();
            }

            if (state is MapError) {
              return Center(child: Text(state.failure.message));
            }

            final markers = (state as MapLoaded).markers;

            return FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(20.0, 0.0),
                initialZoom: 3.0,
                minZoom: 1.0,
                maxZoom: 5.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.travelJournal',
                ),
                MarkerLayer(
                  markers: markers.map((c) {
                    return Marker(
                      point: LatLng(c.lat, c.lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(
                                  context,
                                ).viewInsets.bottom,
                              ),
                              child: FractionallySizedBox(
                                heightFactor: 0.85,
                                child: BlocProvider(
                                  create: (context) => CountryDetailsBloc(
                                    locator<LocalRepo>(),
                                    locator<AuthRepo>(),
                                    locator<SyncService>(),
                                    locator<CountryRepo>(),
                                  )..add(LoadDetails(c.countryCode)),
                                  child: const DetailScreen(),
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
