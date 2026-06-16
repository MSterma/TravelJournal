import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/country.dart';
import '../repositories/country_repo.dart';
import 'country_event.dart';
import 'country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  final CountryRepo repo;

  CountryBloc(this.repo) : super(CountryLoading()) {
    on<LoadCountries>(_onLoadCountries);
    on<SelectCountry>(_onSelectCountry);
    on<ClearSelection>(_onClearSelection);
  }


  Future<void> _onLoadCountries(LoadCountries event, Emitter<CountryState> emit) async {
    emit(CountryLoading());
    try {
      final data = await repo.getCountries();
      emit(CountryLoaded(countries: data));
    } catch (e) {
      //print('Error: $e');
      emit(CountryError(e.toString()));
    }
  }

  void _onSelectCountry(SelectCountry event, Emitter<CountryState> emit) {
    if (state is CountryLoaded) {
      final currentState = state as CountryLoaded;
      emit(CountryLoaded(
        countries: currentState.countries,
        selectedCountry: event.country,
      ));
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<CountryState> emit) {
    if (state is CountryLoaded) {
      final currentState = state as CountryLoaded;
      emit(CountryLoaded(
        countries: currentState.countries,
        selectedCountry: null,
      ));
    }
  }
}