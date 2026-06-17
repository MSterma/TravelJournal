import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/country.dart';
import '../repositories/country_repo.dart';
import '../repositories/local_repo.dart';
import 'country_event.dart';
import 'country_state.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  final CountryRepo repo;
  final LocalRepo localRepo;
  int _currentOffset = 0;
  final int _limit = 25;
  String? _currentQuery;

  CountryBloc(this.repo, this.localRepo) : super(CountryLoading()) {
    on<LoadCountries>(_onLoadCountries);
    on<LoadMoreCountries>(_onLoadMoreCountries);
    on<SearchCountries>(_onSearchCountries);
    on<SelectCountry>(_onSelectCountry);
    on<ClearSelection>(_onClearSelection);
    on<MarkVisited>(_onMarkVisited);
    on<AddPhoto>(_onAddPhoto);
  }

  Future<void> _onLoadCountries(LoadCountries event, Emitter<CountryState> emit) async {
    emit(CountryLoading());
    try {
      _currentOffset = 0;
      _currentQuery = null;
      final data = await repo.getCountries(limit: _limit, offset: _currentOffset);
      emit(CountryLoaded(countries: data, hasReachedMax: data.length < _limit));
    } catch (e) {
      emit(CountryError(e.toString()));
    }
  }

  Future<void> _onSearchCountries(SearchCountries event, Emitter<CountryState> emit) async {
    if (state is CountryLoaded) {
      final currentState = state as CountryLoaded;
      emit(currentState.copyWith(isSearching: true, countries: []));
    } else {
      emit(CountryLoading());
    }

    try {
      _currentOffset = 0;
      _currentQuery = event.query.isEmpty ? null : event.query;
      final data = await repo.getCountries(limit: _limit, offset: _currentOffset, query: _currentQuery);
      emit(CountryLoaded(countries: data, hasReachedMax: data.length < _limit, isSearching: false));
    } catch (e) {
      if (e.toString().contains('404')) {
        emit(CountryLoaded(countries: [], hasReachedMax: true, isSearching: false));
      } else {
        emit(CountryError(e.toString()));
      }
    }
  }

  Future<void> _onLoadMoreCountries(LoadMoreCountries event, Emitter<CountryState> emit) async {
    if (state is CountryLoaded) {
      final currentState = state as CountryLoaded;
      if (currentState.hasReachedMax || currentState.isFetchingMore) return;

      emit(currentState.copyWith(isFetchingMore: true));
      try {
        _currentOffset += _limit;
        final data = await repo.getCountries(limit: _limit, offset: _currentOffset, query: _currentQuery);

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

  Future<void> _onSelectCountry(SelectCountry event, Emitter<CountryState> emit) async {
    final visited = await localRepo.checkVisited(event.country.name);
    final photos = await localRepo.getPhotos(event.country.name);

    if (state is CountryLoaded) {
      final currentState = state as CountryLoaded;
      emit(currentState.copyWith(
        selectedCountry: event.country,
        isVisited: visited,
        photos: photos,
      ));
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
        isSearching: currentState.isSearching,
      ));
    }
  }

  Future<void> _onMarkVisited(MarkVisited event, Emitter<CountryState> emit) async {
    try {
      await localRepo.markVisited(event.countryName);
      if (state is CountryLoaded) {
        final currentState = state as CountryLoaded;
        emit(currentState.copyWith(isVisited: true));
      }
    } catch (e) {
      //print("err: $e");
    }
  }

  Future<void> _onAddPhoto(AddPhoto event, Emitter<CountryState> emit) async {
    try {
      await localRepo.addPhoto(event.countryName, event.imagePath);
      if (state is CountryLoaded) {
        final currentState = state as CountryLoaded;
        final newPhotos = List<String>.from(currentState.photos)..add(event.imagePath);
        emit(currentState.copyWith(photos: newPhotos));
      }
    } catch (e) {
    }
  }
}