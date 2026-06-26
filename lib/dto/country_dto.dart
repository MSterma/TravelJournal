import 'package:freezed_annotation/freezed_annotation.dart';

part 'country_dto.freezed.dart';
part 'country_dto.g.dart';

@freezed
abstract class CountryDto with _$CountryDto {
  const CountryDto._();

  const factory CountryDto({
    @JsonKey(name: 'names') CountryNamesDto? names,
    @JsonKey(name: 'capitals') List<dynamic>? capitals,
    @JsonKey(name: 'flag') CountryFlagDto? flag,
    int? population,
    String? region,
    @JsonKey(name: 'coordinates') CountryCoordinatesDto? coordinates,
  }) = _CountryDto;

  factory CountryDto.fromJson(Map<String, dynamic> json) =>
      _$CountryDtoFromJson(json);

  String? get firstCapital {
    if (capitals == null || capitals!.isEmpty) return null;
    final firstCap = capitals!.first;
    if (firstCap is Map && firstCap['name'] != null) {
      return firstCap['name'].toString();
    } else if (firstCap is String) {
      return firstCap;
    }
    return null;
  }
}

@freezed
abstract class CountryNamesDto with _$CountryNamesDto {
  const factory CountryNamesDto({String? common}) = _CountryNamesDto;

  factory CountryNamesDto.fromJson(Map<String, dynamic> json) =>
      _$CountryNamesDtoFromJson(json);
}

@freezed
abstract class CountryFlagDto with _$CountryFlagDto {
  const factory CountryFlagDto({@JsonKey(name: 'url_png') String? urlPng}) =
      _CountryFlagDto;

  factory CountryFlagDto.fromJson(Map<String, dynamic> json) =>
      _$CountryFlagDtoFromJson(json);
}

@freezed
abstract class CountryCoordinatesDto with _$CountryCoordinatesDto {
  const factory CountryCoordinatesDto({double? lat, double? lng}) =
      _CountryCoordinatesDto;

  factory CountryCoordinatesDto.fromJson(Map<String, dynamic> json) =>
      _$CountryCoordinatesDtoFromJson(json);
}
