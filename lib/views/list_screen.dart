import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../l10n/app_localizations.dart';
import '../models/country.dart';
import '../bloc/country_bloc.dart';
import '../bloc/country_event.dart';

class ListScreen extends StatelessWidget {
  final List<Country> countries;

  const ListScreen({super.key, required this.countries});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text('${l10n.countryList}')),
      body: ListView.builder(
        itemCount: countries.length,
        itemBuilder: (context, index) {
          final c = countries[index];
          return ListTile(
            title: Text(c.name),
            onTap: () => context.read<CountryBloc>().add(SelectCountry(c)),
          );
        },
      ),
    );
  }
}