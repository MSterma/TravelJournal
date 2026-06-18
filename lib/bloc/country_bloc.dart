import 'package:flutter_bloc/flutter_bloc.dart';
import '../repositories/country_repo.dart';
import 'country_event.dart';
import 'country_state.dart';
import '../locator.dart';
import '../services/sync_service.dart';
import '../repositories/auth_repo.dart';

class CountryBloc extends Bloc<CountryEvent, CountryState> {
  final CountryRepo repo;
  int _currentOffset = 0;
  final int _limit = 25;
  String? _currentQuery;

  CountryBloc(this.repo) : super(const CountryState.loading()) {
    on<LoadCountries>(_onLoadCountries);
    on<LoadMoreCountries>(_onLoadMoreCountries);
    on<SearchCountries>(_onSearchCountries);
  }

  Future<void> _onLoadCountries(LoadCountries event, Emitter<CountryState> emit) async {
    _runBackgroundSync();
    emit(const CountryState.loading());
    try {
      _currentOffset = 0;
      _currentQuery = null;
      final data = await repo.getCountries(limit: _limit, offset: _currentOffset);
      emit(CountryState.loaded(countries: data, hasReachedMax: data.length < _limit));
    } catch (e) {
      emit(CountryState.error(e.toString()));
    }
  }

  Future<void> _onSearchCountries(SearchCountries event, Emitter<CountryState> emit) async {
    _runBackgroundSync();

    if (state case final CountryLoaded loadedState) {
      emit(loadedState.copyWith(isSearching: true, countries: []));
    } else {
      emit(const CountryState.loading());
    }

    try {
      _currentOffset = 0;
      _currentQuery = event.query.isEmpty ? null : event.query;
      final data = await repo.getCountries(limit: _limit, offset: _currentOffset, query: _currentQuery);
      emit(CountryState.loaded(countries: data, hasReachedMax: data.length < _limit, isSearching: false));
    } catch (e) {
      if (e.toString().contains('404')) {
        emit(const CountryState.loaded(countries: [], hasReachedMax: true, isSearching: false));
      } else {
        emit(CountryState.error(e.toString()));
      }
    }
  }

  void _runBackgroundSync() async {
    try {
      final userId = await locator<AuthRepo>().getCurrentUserId();
      if (userId != null) {
        await locator<SyncService>().syncCloudToLocal(userId);
        await locator<SyncService>().syncLocalToCloud(userId);
      }
    } catch (_) {}
  }

  Future<void> _onLoadMoreCountries(LoadMoreCountries event, Emitter<CountryState> emit) async {
    _runBackgroundSync();

    if (state case final CountryLoaded loadedState) {
      if (loadedState.hasReachedMax || loadedState.isFetchingMore) return;

      emit(loadedState.copyWith(isFetchingMore: true));
      try {
        _currentOffset += _limit;
        final data = await repo.getCountries(limit: _limit, offset: _currentOffset, query: _currentQuery);

        if (data.isEmpty) {
          emit(loadedState.copyWith(hasReachedMax: true, isFetchingMore: false));
        } else {
          emit(loadedState.copyWith(
            countries: [...loadedState.countries, ...data],
            hasReachedMax: data.length < _limit,
            isFetchingMore: false,
          ));
        }
      } catch (_) {
        emit(loadedState.copyWith(isFetchingMore: false));
      }
    }
  }
}