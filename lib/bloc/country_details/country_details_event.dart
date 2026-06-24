import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/country.dart';

part 'country_details_event.freezed.dart';

@freezed
abstract class CountryDetailsEvent with _$CountryDetailsEvent {
  const factory CountryDetailsEvent.loadDetails(String countryName, {Country? country}) = LoadDetails;
  const factory CountryDetailsEvent.markCountryVisited(String countryName, double lat, double lng) = MarkCountryVisited;
  const factory CountryDetailsEvent.addCountryPhoto(String countryName, String imagePath) = AddCountryPhoto;
}
