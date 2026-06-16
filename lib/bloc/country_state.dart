import '../models/country.dart';

abstract class CountryState {}

class CountryLoading extends CountryState {}

class CountryError extends CountryState {
  final String message;
  CountryError(this.message);
}

class CountryLoaded extends CountryState {
  final List<Country> countries;
  final Country? selectedCountry;
  final bool hasReachedMax;
  final bool isFetchingMore;

  CountryLoaded({
    required this.countries,
    this.selectedCountry,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
  });

  CountryLoaded copyWith({
    List<Country>? countries,
    Country? selectedCountry,
    bool? hasReachedMax,
    bool? isFetchingMore,
  }) {
    return CountryLoaded(
      countries: countries ?? this.countries,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
    );
  }
}