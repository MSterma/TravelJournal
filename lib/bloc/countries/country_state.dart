import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/country.dart';
import '../common/failures.dart';

part 'country_state.freezed.dart';

@freezed
abstract class CountryState with _$CountryState {
  const factory CountryState.loading() = CountryLoading;
  const factory CountryState.error(Failure failure) = CountryError;
  const factory CountryState.loaded({
    required List<Country> countries,
    Country? selectedCountry,
    @Default(false) bool hasReachedMax,
    @Default(false) bool isFetchingMore,
    @Default(false) bool isSearching,
    @Default(false) bool isVisited,
    @Default([]) List<String> photos,
  }) = CountryLoaded;
}
