import '../dto/country_dto.dart';
import '../models/country.dart';

class CountryMapper {
  static Country fromDto(CountryDto dto) {
    return Country(
      name: dto.names?.common ?? '',
      capital: dto.firstCapital,
      flagUrl: dto.flag?.urlPng,
      population: dto.population ?? 0,
      region: dto.region,
      lat: dto.coordinates?.lat ?? 0.0,
      lng: dto.coordinates?.lng ?? 0.0,
    );
  }
}
