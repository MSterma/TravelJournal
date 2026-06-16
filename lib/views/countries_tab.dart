import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/country_bloc.dart';
import '../bloc/country_event.dart';
import '../bloc/country_state.dart';
import '../l10n/app_localizations.dart';
import 'list_screen.dart';
import 'detail_screen.dart';

class CountriesTab extends StatelessWidget {
  const CountriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<CountryBloc, CountryState>(
      builder: (context, state) {
        if (state is CountryLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is CountryError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<CountryBloc>().add(LoadCountries()),
                    child: Text(l10n?.tryAgain ?? 'Try again'),
                  )
                ],
              ),
            ),
          );
        } else if (state is CountryLoaded) {
          if (state.selectedCountry == null) {
            return ListScreen(
              countries: state.countries,
              isFetchingMore: state.isFetchingMore,
              isSearching: state.isSearching,
            );
          } else {
            return DetailScreen(country: state.selectedCountry!);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}