import 'package:freezed_annotation/freezed_annotation.dart';

part 'country.freezed.dart';

@freezed
abstract class Country with _$Country {
  const Country._();

  const factory Country({
    required String name,
    String? capital,
    String? flagUrl,
    required int population,
    String? region,
    required double lat,
    required double lng,
  }) = _Country;
}
