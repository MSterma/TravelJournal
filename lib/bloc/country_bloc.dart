import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/country.dart';
import '../repositories/country_repo.dart';
import 'country_event.dart';
import 'country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  final CountryRepo repo;
  int _currentOffset = 0;
  final int _limit = 25;

  CountryBloc(this.repo) : super(CountryLoading()) {
    on<LoadCountries>(_onLoadCountries);
    on<LoadMoreCountries>(_onLoadMoreCountries);
    on<SelectCountry>(_onSelectCountry);
    on<ClearSelection>(_onClearSelection);
  }

  Future<void> _onLoadCountries(LoadCountries event, Emitter<CountryState> emit) async {
    emit(CountryLoading());
    try {
      _currentOffset = 0;
      final data = await repo.getCountries(limit: _limit, offset: _currentOffset);
      emit(CountryLoaded(
        countries: data,
        hasReachedMax: data.length < _limit,
      ));
    } catch (e) {
      emit(CountryError(e.toString()));
    }
  }

  Future<void> _onLoadMoreCountries(LoadMoreCountries event, Emitter<CountryState> emit) async {
    if (state is CountryLoaded) {
      final currentState = state as CountryLoaded;

      if (currentState.hasReachedMax || currentState.isFetchingMore) return;

      emit(currentState.copyWith(isFetchingMore: true));

      try {
        _currentOffset += _limit;
        final data = await repo.getCountries(limit: _limit, offset: _currentOffset);

        if (data.isEmpty) {
          emit(currentState.copyWith(hasReachedMax: true, isFetchingMore: false));
        } else {
          emit(currentState.copyWith(
            countries: List.of(currentState.countries)..addAll(data),
            hasReachedMax: data.length < _limit,
            isFetchingMore: false,
          ));
        }
      } catch (e) {
        emit(currentState.copyWith(isFetchingMore: false));
      }
    }
  }

  void _onSelectCountry(SelectCountry event, Emitter<CountryState> emit) {
    if (state is CountryLoaded) {
      final currentState = state as CountryLoaded;
      emit(currentState.copyWith(selectedCountry: event.country));
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<CountryState> emit) {
    if (state is CountryLoaded) {
      final currentState = state as CountryLoaded;
      emit(CountryLoaded(
        countries: currentState.countries,
        selectedCountry: null,
        hasReachedMax: currentState.hasReachedMax,
        isFetchingMore: currentState.isFetchingMore,
      ));
    }
  }
}