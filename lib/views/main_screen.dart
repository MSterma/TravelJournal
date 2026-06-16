import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/country_bloc.dart';
import '../bloc/country_event.dart';
import '../bloc/country_state.dart';
import 'list_screen.dart';
import 'detail_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CountryBloc, CountryState>(
      builder: (context, state) {
        if (state is CountryLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        } else if (state is CountryError) {
          return Scaffold(
            body: Center(
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
                      child: const Text('Spróbuj ponownie'),
                    )
                  ],
                ),
              ),
            ),
          );
        } else if (state is CountryLoaded) {
          if (state.selectedCountry == null) {
            return ListScreen(countries: state.countries);
          } else {
            return DetailScreen(country: state.selectedCountry!);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }
}