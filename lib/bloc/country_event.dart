import '../models/country.dart';

abstract class CountryEvent {}

class LoadCountries extends CountryEvent {}

class LoadMoreCountries extends CountryEvent {}

class SearchCountries extends CountryEvent {
  SearchCountries(this.query);
  final String query;
}

class SelectCountry extends CountryEvent {
  SelectCountry(this.country);
  final Country country;
}
class MarkVisited extends CountryEvent {
  MarkVisited(this.countryName);
  final String countryName;
}
class ClearSelection extends CountryEvent {}
class AddPhoto extends CountryEvent {
  AddPhoto(this.countryName, this.imagePath);
  final String countryName;
  final String imagePath;
}