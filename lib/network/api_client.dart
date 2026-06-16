import 'package:dio/dio.dart';

class ApiClient {
  final Dio dio;

  ApiClient(this.dio) {
    dio.options.baseUrl = 'https://api.restcountries.com/countries/v5';
    dio.options.headers = {'Authorization': 'Bearer '};
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