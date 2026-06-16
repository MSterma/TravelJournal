import '../models/country.dart';

abstract class CountryEvent {}

class LoadCountries extends CountryEvent {}

class SelectCountry extends CountryEvent {
  SelectCountry(this.country);
  final Country country;
}

class ClearSelection extends CountryEvent {}