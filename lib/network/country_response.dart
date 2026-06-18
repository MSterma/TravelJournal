import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/country.dart';

part 'country_response.g.dart';

@JsonSerializable(createToJson: false)
class CountryResponse {
  final CountryData? data;
  CountryResponse(this.data);
  factory CountryResponse.fromJson(Map<String, dynamic> json) => _$CountryResponseFromJson(json);
}

@JsonSerializable(createToJson: false)
class CountryData {
  @JsonKey(defaultValue: [])
  final List<Country> objects;
  CountryData(this.objects);
  factory CountryData.fromJson(Map<String, dynamic> json) => _$CountryDataFromJson(json);
}