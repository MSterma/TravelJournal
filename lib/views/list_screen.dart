import 'package:flutter/material.dart';
import '../viewmodels/country_viewmodel.dart';

class ListScreen extends StatelessWidget {
  final CountryViewModel vm;

  const ListScreen({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lista Krajów')),
      body: ListView.builder(
        itemCount: vm.countries.length,
        itemBuilder: (context, index) {
          final c = vm.countries[index];
          return ListTile(
            title: Text(c.name),
            onTap: () => vm.select(c),
          );
        },
      ),
    );
  }
}