import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../models/country.dart';
import '../bloc/country_details_bloc.dart';
import '../bloc/country_details_event.dart';
import '../bloc/country_details_state.dart';
import '../l10n/app_localizations.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.country});
  final Country country;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0, top: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Center(
              child: Text(country.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            if (country.flagUrl.isNotEmpty)
              Center(
                child: Image.network(
                  country.flagUrl,
                  height: 100,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 50),
                ),
              ),
            const SizedBox(height: 24),
            Text('${l10n.capital}: ${country.capital}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('${l10n.population}: ${country.population}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('${l10n.region}: ${country.region}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('${l10n.coordinates}: ${country.lat}, ${country.lng}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 32),
            BlocConsumer<CountryDetailsBloc, CountryDetailsState>(
              listener: (context, state) {
                if (state is DetailsLoaded && state.failure != null) {
                  String msg = state.failure!.message;
                  if (msg == "Failed to load details") msg = l10n.errorLoadDetails;
                  else if (msg == "Failed to mark as visited") msg = l10n.errorMarkVisited;
                  else if (msg == "Failed to add photo") msg = l10n.errorAddPhoto;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg), backgroundColor: Colors.red),
                  );
                }
              },
              builder: (context, state) {
                if (state is DetailsLoaded) {
                  if (state.isVisited) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 28),
                            const SizedBox(width: 8),
                            Text(l10n.countryVisited, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add_a_photo),
                          onPressed: () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(source: ImageSource.gallery);
                            if (image != null && context.mounted) {
                              context.read<CountryDetailsBloc>().add(AddCountryPhoto(country.name, image.path));
                            }
                          },
                          label: Text(l10n.addPhoto),
                        ),
                        const SizedBox(height: 16),
                        if (state.photos.isNotEmpty)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
                            itemCount: state.photos.length,
                            itemBuilder: (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.file(File(state.photos[index]), fit: BoxFit.cover),
                              );
                            },
                          )
                      ],
                    );
                  } else {
                    return Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add_location),
                        onPressed: () => context.read<CountryDetailsBloc>().add(MarkCountryVisited(country.name, country.lat, country.lng)),
                        label: Text(l10n.markVisited),
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}