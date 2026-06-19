import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/countries/country_bloc.dart';
import '../../bloc/countries/country_event.dart';
import '../../bloc/countries/country_state.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/error_view.dart';
import 'list_screen.dart';

class CountriesTab extends StatelessWidget {
  const CountriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<CountryBloc, CountryState>(
      builder: (context, state) {
        if (state is CountryLoading) {
          return const LoadingIndicator();
        } else if (state is CountryError) {
          return ErrorView(
            message: l10n?.errorFetchCountries ?? 'Error',
            onRetry: () => context.read<CountryBloc>().add(LoadCountries()),
            retryLabel: l10n?.tryAgain,
          );
        } else if (state is CountryLoaded) {
          return ListScreen(
            countries: state.countries,
            isFetchingMore: state.isFetchingMore,
            isSearching: state.isSearching,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
