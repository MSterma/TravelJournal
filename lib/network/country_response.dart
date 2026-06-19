import 'package:freezed_annotation/freezed_annotation.dart';
import '../dto/country_dto.dart';

part 'country_response.g.dart';

@JsonSerializable(createToJson: false)
class CountryResponse {
  factory CountryResponse.fromJson(Map<String, dynamic> json) => _$CountryResponseFromJson(json);
  CountryResponse(this.data);
  final CountryData? data;
}

@JsonSerializable(createToJson: false)
class CountryData {

  CountryData(this.objects);
  factory CountryData.fromJson(Map<String, dynamic> json) => _$CountryDataFromJson(json);
  @JsonKey(defaultValue: [])
  final List<CountryDto> objects;
}