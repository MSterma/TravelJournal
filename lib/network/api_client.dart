import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'country_response.dart';
import 'app_urls.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) {
    dio.options.headers['Authorization'] = 'Bearer ';
    return _ApiClient(dio, baseUrl: baseUrl ?? AppUrls.countriesBaseUrl);
  }

  @GET(AppUrls.countriesEndpoint)
  Future<CountryResponse> getCountries(
      @Query('limit') int limit,
      @Query('offset') int offset,
      @Query('q') String? query,
      );
}
