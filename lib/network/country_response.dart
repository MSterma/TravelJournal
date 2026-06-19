import 'package:freezed_annotation/freezed_annotation.dart';
import '../dto/country_dto.dart';

part 'country_response.freezed.dart';
part 'country_response.g.dart';

@freezed
abstract class CountryResponse with _$CountryResponse {
  const factory CountryResponse({
    CountryData? data,
  }) = _CountryResponse;

  factory CountryResponse.fromJson(Map<String, dynamic> json) => _$CountryResponseFromJson(json);
}

@freezed
abstract class CountryData with _$CountryData {
  const factory CountryData({
    @Default([]) List<CountryDto> objects,
  }) = _CountryData;

  factory CountryData.fromJson(Map<String, dynamic> json) => _$CountryDataFromJson(json);
}
