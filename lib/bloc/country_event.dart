import '../models/country.dart';

abstract class CountryEvent {}

class LoadCountries extends CountryEvent {}

class LoadMoreCountries extends CountryEvent {}

class SearchCountries extends CountryEvent {
  final String query;
  SearchCountries(this.query);
}

class SelectCountry extends CountryEvent {
  final Country country;
  SelectCountry(this.country);
}
class MarkVisited extends CountryEvent {
  final String countryName;
  MarkVisited(this.countryName);
}
class ClearSelection extends CountryEvent {}
class AddPhoto extends CountryEvent {
  final String countryName;
  final String imagePath;
  AddPhoto(this.countryName, this.imagePath);
}