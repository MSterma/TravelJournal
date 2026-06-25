import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/country_details/country_details_bloc.dart';
import '../../../bloc/country_details/country_details_event.dart';
import '../../../locator.dart';
import '../../../models/country.dart';
import '../../../repositories/auth_repo.dart';
import '../../../repositories/country_repo.dart';
import '../../../repositories/local_repo.dart';
import '../../countries/detail_screen.dart';

import '../../../services/sync_service.dart';

class CountryListItem extends StatelessWidget {
  const CountryListItem({super.key, required this.country});

  final Country country;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(country.name),
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
              child: BlocProvider(
                create: (context) => CountryDetailsBloc(
                  locator<LocalRepo>(),
                  locator<AuthRepo>(),
                  locator<SyncService>(),
                  locator<CountryRepo>(),
                )..add(LoadDetails(country.name, country: country)),
                child: DetailScreen(country: country),
              ),
            ),
          ),
        );
      },
    );
  }
}
