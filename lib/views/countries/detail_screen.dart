import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/country.dart';
import '../../bloc/country_details/country_details_bloc.dart';
import '../../bloc/country_details/country_details_event.dart';
import '../../bloc/country_details/country_details_state.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/photo_viewer.dart';
import '../widgets/common/loading_indicator.dart';
import '../widgets/common/image_placeholder.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, this.country});
  final Country? country;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<CountryDetailsBloc, CountryDetailsState>(
      listener: (context, state) {
        if (state is DetailsLoaded && state.failure != null) {
          String msg = state.failure!.message;
          if (msg == "Failed to load details") {
            msg = l10n.errorLoadDetails;
          } else if (msg == "Failed to mark as visited") {
            msg = l10n.errorMarkVisited;
          } else if (msg == "Failed to add photo") {
            msg = l10n.errorAddPhoto;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: Colors.red),
          );
        }
      },
      builder: (context, state) {
        if (state is DetailsLoading) {
          return const LoadingIndicator();
        }

        if (state is! DetailsLoaded) {
          return const SizedBox.shrink();
        }

        final displayCountry = state.country ??
            country ??
            Country(
              name: "Unknown",
              lat: 0,
              lng: 0,
              capital: l10n.noData,
              flagUrl: '',
              population: 0,
              region: l10n.noData,
            );

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
              top: 8.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    displayCountry.name,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                if (displayCountry.flagUrl != null &&
                    displayCountry.flagUrl!.isNotEmpty)
                  Center(
                    child: GestureDetector(
                      onTap: () => PhotoViewer.show(
                        context,
                        photos: [displayCountry.flagUrl!],
                        source: PhotoSource.network,
                      ),
                      child: Image.network(
                        displayCountry.flagUrl!,
                        height: 100,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.error, size: 50),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  '${l10n.capital}: ${displayCountry.capital ?? l10n.noCapital}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.population}: ${displayCountry.population}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.region}: ${displayCountry.region ?? l10n.noRegion}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.coordinates}: ${displayCountry.lat}, ${displayCountry.lng}',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),
                if (state.isVisited)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.countryVisited,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_a_photo),
                        onPressed: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (image != null && context.mounted) {
                            context.read<CountryDetailsBloc>().add(
                                  AddCountryPhoto(
                                      displayCountry.name, image.path),
                                );
                          }
                        },
                        label: Text(l10n.addPhoto),
                      ),
                      const SizedBox(height: 16),
                      if (state.photos.isNotEmpty)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: state.photos.length,
                          itemBuilder: (context, index) {
                            final path = state.photos[index];
                            final isPlaceholder = path == '__PLACEHOLDER__';
                            final exists =
                                !isPlaceholder && File(path).existsSync();

                            return GestureDetector(
                              onTap: () => PhotoViewer.show(
                                context,
                                photos: state.photos,
                                initialIndex: index,
                                source: PhotoSource.file,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: exists
                                    ? Image.file(
                                        File(path),
                                        fit: BoxFit.cover,
                                      )
                                    : const ImagePlaceholder(
                                        width: 100,
                                        height: 100,
                                      ),
                              ),
                            );
                          },
                        )
                    ],
                  )
                else
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_location),
                      onPressed: () => context.read<CountryDetailsBloc>().add(
                            MarkCountryVisited(
                              displayCountry.name,
                              displayCountry.lat,
                              displayCountry.lng,
                            ),
                          ),
                      label: Text(l10n.markVisited),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

