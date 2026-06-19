import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/country.dart';

part 'country_event.freezed.dart';

@freezed
abstract class CountryEvent with _$CountryEvent {
  const factory CountryEvent.loadCountries() = LoadCountries;
  const factory CountryEvent.loadMoreCountries() = LoadMoreCountries;
  const factory CountryEvent.searchCountries(String query) = SearchCountries;
  const factory CountryEvent.selectCountry(Country country) = SelectCountry;
  const factory CountryEvent.markVisited(String countryName) = MarkVisited;
  const factory CountryEvent.clearSelection() = ClearSelection;
  const factory CountryEvent.addPhoto(String countryName, String imagePath) = AddPhoto;
}