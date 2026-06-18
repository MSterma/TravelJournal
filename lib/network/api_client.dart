import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'country_response.dart';

part 'api_client.g.dart';

@RestApi(baseUrl: 'https://api.restcountries.com/countries/v5')
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) {
    dio.options.headers = {'Authorization': 'Bearer '};
    return _ApiClient(dio, baseUrl: baseUrl);
  }

  @GET('?pretty=1')
  Future<CountryResponse> getCountries(
      @Query('limit') int limit,
      @Query('offset') int offset,
      @Query('q') String? query,
      );
}