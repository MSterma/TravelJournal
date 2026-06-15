import 'package:flutter/material.dart';
import '../viewmodels/country_viewmodel.dart';

class DetailScreen extends StatelessWidget {
  final CountryViewModel vm;

  const DetailScreen({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    final c = vm.selected!;
    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: vm.clear,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kraj: ${c.name}', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text('Powierzchnia: ${c.areaSqM} m^2', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Populacja: ${c.population}', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}