import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/country.dart';
import '../bloc/country_bloc.dart';
import '../bloc/country_event.dart';

class DetailScreen extends StatelessWidget {
  final Country country;

  const DetailScreen({super.key, required this.country});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(country.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.read<CountryBloc>().add(ClearSelection()),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (country.flagUrl.isNotEmpty)
              Center(
                child: Image.network(
                  country.flagUrl,
                  height: 150,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 50),
                ),
              ),
            const SizedBox(height: 24),
            Text('Kraj: ${country.name}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Divider(),
            Text('Stolica: ${country.capital}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Populacja: ${country.population}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Region: ${country.region}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Współrzędne: ${country.lat}, ${country.lng}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}