import 'package:freezed_annotation/freezed_annotation.dart';

part 'country.freezed.dart';

@freezed
abstract class Country with _$Country {
  const Country._();

  const factory Country({
    required String name,
    required String capital,
    required String flagUrl,
    required int population,
    required String region,
    required double lat,
    required double lng,
  }) = _Country;

  factory Country.fromJson(Map<String, dynamic> json) {
    return _Country(
      name: json['names']?['common'] ?? 'Brak nazwy',
      capital: (json['capitals'] as List?)?.isNotEmpty == true ? json['capitals']![0]['name'] ?? 'Brak stolicy' : 'Brak stolicy',
      flagUrl: json['flag']?['url_png'] ?? '',
      population: json['population'] ?? 0,
      region: json['region'] ?? 'Brak regionu',
      lat: json['coordinates']?['lat']?.toDouble() ?? 0.0,
      lng: json['coordinates']?['lng']?.toDouble() ?? 0.0,
    );
  }
}