import '../models/country.dart';
import '../network/api_client.dart';

class CountryRepo {
  final ApiClient apiClient;

  CountryRepo(this.apiClient);

  Future<List<Country>> getCountries({int limit = 25, int offset = 0, String? query}) async {
    final response = await apiClient.getCountries(limit, offset, query);
    return response.data?.objects ?? [];
  }
}