import '../models/country.dart';
import '../network/api_client.dart';

class CountryRepo {
  final ApiClient apiClient;

  CountryRepo(this.apiClient);

  Future<List<Country>> getCountries() async {
    final responseData = await apiClient.get('?pretty=1');

    final dataMap = responseData['data'];
    final list = dataMap != null ? dataMap['objects'] : [];

    if (list is List) {
      return list.map((e) => Country.fromJson(e)).toList();
    }
    return [];
  }
}