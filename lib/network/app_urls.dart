abstract class AppUrls {
  static const String countriesBaseUrl =
      'https://api.restcountries.com/countries/v5';
  static const String countriesEndpoint = '?pretty=1';
  static String countriesPaginated(int limit, int offset, [String? query]) {
    String url = '?pretty=1&limit=$limit&offset=$offset';
    if (query != null && query.isNotEmpty) {
      url += '&q=$query';
    }
    return url;
  }
}
