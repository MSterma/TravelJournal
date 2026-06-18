import '../models/country.dart';
import '../network/api_client.dart';
import '../network/app_urls.dart';

class CountryRepo {
  final ApiClient apiClient;

  CountryRepo(this.apiClient);

  Future<List<Country>> getCountries({int limit = 25, int offset = 0, String? query}) async {
    final responseData = await apiClient.get(AppUrls.countriesPaginated(limit, offset, query));

    final dataMap = responseData['data'];
    final list = dataMap != null ? dataMap['objects'] : [];

    if (list is List) {
      return list.map((e) => Country.fromJson(e)).toList();
    }
    return [];
  }
}