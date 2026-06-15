import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/country.dart';
import '../repositories/country_repo.dart';
import 'country_event.dart';
import 'country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  final CountryRepo repo;

  CountryBloc(this.repo) : super(CountryLoading()) {
    on<LoadCountries>((event, emit) {
      final data = repo.getCountries();
      emit(CountryLoaded(countries: data));
    });

    on<SelectCountry>((event, emit) {
      if (state is CountryLoaded) {
        final currentState = state as CountryLoaded;
        emit(CountryLoaded(
          countries: currentState.countries,
          selectedCountry: event.country,
        ));
      }
    });

    on<ClearSelection>((event, emit) {
      if (state is CountryLoaded) {
        final currentState = state as CountryLoaded;
        emit(CountryLoaded(
          countries: currentState.countries,
          selectedCountry: null,
        ));
      }
    });
  }
}