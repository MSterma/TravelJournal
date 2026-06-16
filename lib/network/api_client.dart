import 'package:dio/dio.dart';
import 'package:travel_journal/network/app_urls.dart';

class ApiClient {
  final Dio dio;

  ApiClient(this.dio) {
    dio.options.baseUrl = AppUrls.countriesBaseUrl;
    dio.options.headers = {'Authorization': 'Bearer rc_live_4aa91fd3a5bd41c493237726cd31ad52'};
  }

  Future<dynamic> get(String path) async {
    try {
      final response = await dio.get(path);
      return response.data;
    } catch (e) {
      throw Exception('ApiClient error: $e');
    }
  }
}