import '../models/country.dart';

abstract class CountryEvent {}

class LoadCountries extends CountryEvent {}

class LoadMoreCountries extends CountryEvent {}

class SelectCountry extends CountryEvent {
  final Country country;
  SelectCountry(this.country);
}

class ClearSelection extends CountryEvent {}