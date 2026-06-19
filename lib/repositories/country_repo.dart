import '../models/country.dart';
import '../network/api_client.dart';
import '../mappers/country_mapper.dart';

class CountryRepo {

  CountryRepo(this.apiClient);
  final ApiClient apiClient;

  Future<List<Country>> getCountries({int limit = 25, int offset = 0, String? query}) async {
    final response = await apiClient.getCountries(limit, offset, query);
    final dtos = response.data?.objects ?? [];

    return dtos.map((dto) => CountryMapper.fromDto(dto)).toList();
  }
}