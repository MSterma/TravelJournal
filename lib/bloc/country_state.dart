import '../models/country.dart';

abstract class CountryState {}

class CountryLoading extends CountryState {}

class CountryLoaded extends CountryState {
  final List<Country> countries;
  final Country? selectedCountry;

  CountryLoaded({required this.countries, this.selectedCountry});
}