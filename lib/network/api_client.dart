import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'country_response.dart';
import 'app_urls.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'api_client.g.dart';

@RestApi()
abstract class ApiClient {
  factory ApiClient(Dio dio, {String? baseUrl}) {
    final token = dotenv.env['API_AUTH_TOKEN'] ?? '';
    dio.options.headers['Authorization'] = 'Bearer $token';
    return _ApiClient(dio, baseUrl: baseUrl ?? AppUrls.countriesBaseUrl);
  }

  @GET(AppUrls.countriesEndpoint)
  Future<CountryResponse> getCountries(
      @Query('limit') int limit,
      @Query('offset') int offset,
      @Query('q') String? query,
      );
}
