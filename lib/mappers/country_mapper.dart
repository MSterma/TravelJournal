import '../dto/country_dto.dart';
import '../models/country.dart';

class CountryMapper {
  static Country fromDto(CountryDto dto) {
    String? parsedCapital;

    if (dto.capitals != null && dto.capitals!.isNotEmpty) {
      final firstCap = dto.capitals!.first;
      if (firstCap is Map && firstCap['name'] != null) {
        parsedCapital = firstCap['name'].toString();
      } else if (firstCap is String) {
        parsedCapital = firstCap;
      }
    }

    return Country(
      name: dto.names?.common ?? '',
      capital: parsedCapital,
      flagUrl: dto.flag?.urlPng,
      population: dto.population ?? 0,
      region: dto.region,
      lat: dto.coordinates?.lat ?? 0.0,
      lng: dto.coordinates?.lng ?? 0.0,
    );
  }
}