import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../locator.dart';
import '../../repositories/local_repo.dart';
import '../../repositories/auth_repo.dart';
import '../../repositories/country_repo.dart';
import '../../database/app_database.dart';
import '../../models/country.dart';
import '../../bloc/country_details/country_details_bloc.dart';
import '../../bloc/country_details/country_details_event.dart';
import '../../l10n/app_localizations.dart';
import '../../services/sync_service.dart';
import '../countries/detail_screen.dart';
import '../widgets/loading_indicator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<VisitedCountry>> _futureMarkers;

  @override
  void initState() {
    super.initState();
    _futureMarkers = _loadMarkers();
  }

  Future<List<VisitedCountry>> _loadMarkers() async {
    final userId = await locator<AuthRepo>().getCurrentUserId();
    if (userId == null) return [];
    return await locator<LocalRepo>().getVisitedWithCoords(userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.visitedPlaces)),
      body: FutureBuilder<List<VisitedCountry>>(
        future: _futureMarkers,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingIndicator();
          }

          final visited = snapshot.data ?? [];

          return FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(20.0, 0.0),
              initialZoom: 2.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.travelJournal',
              ),
              MarkerLayer(
                markers: visited.map((c) {
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
                              bottom: MediaQuery.of(context).viewInsets.bottom,
                            ),
                            child: FractionallySizedBox(
                              heightFactor: 0.85,
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20),
                                  ),
                                ),
                                child: FutureBuilder<List<Country>>(
                                  future: locator<CountryRepo>()
                                      .getCountries(query: c.countryCode),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const LoadingIndicator();
                                    }

                                    Country displayCountry;
                                    if (snapshot.hasData &&
                                        snapshot.data!.isNotEmpty) {
                                      displayCountry = snapshot.data!.first;
                                    } else {
                                      displayCountry = Country(
                                        name: c.countryCode,
                                        lat: c.lat,
                                        lng: c.lng,
                                        capital: l10n.noData,
                                        flagUrl: '',
                                        population: 0,
                                        region: l10n.noData,
                                      );
                                    }

                                    return BlocProvider(
                                      create: (context) => CountryDetailsBloc(
                                        locator<LocalRepo>(),
                                        locator<AuthRepo>(),
                                        locator<SyncService>(),
                                      )..add(LoadDetails(displayCountry.name)),
                                      child: DetailScreen(
                                        country: displayCountry,
                                      ),
                                    );
                                  },
                                ),
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
    );
  }
}
