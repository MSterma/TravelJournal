abstract class AppUrls {
  static const String countriesBaseUrl = 'https://api.restcountries.com/countries/v5';
  static const String countriesEndpoint = '?pretty=1';
  static String countriesPaginated(int limit, int offset) => '?pretty=1&limit=$limit&offset=$offset';
}