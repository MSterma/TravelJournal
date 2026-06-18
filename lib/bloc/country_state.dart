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
  final bool isSearching;
  final bool isVisited;
  final List<String> photos;

  CountryLoaded({
    required this.countries,
    this.selectedCountry,
    this.hasReachedMax = false,
    this.isFetchingMore = false,
    this.isSearching = false,
    this.isVisited = false,
    this.photos = const [],
  });

  CountryLoaded copyWith({
    List<Country>? countries,
    Country? selectedCountry,
    bool? hasReachedMax,
    bool? isFetchingMore,
    bool? isSearching,
    bool? isVisited,
    List<String>? photos,
  }) {
    return CountryLoaded(
      countries: countries ?? this.countries,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      isSearching: isSearching ?? this.isSearching,
      isVisited: isVisited ?? this.isVisited,
      photos: photos ?? this.photos,
    );
  }
}