import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'network/api_client.dart';
import 'repositories/country_repo.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<Dio>(() => Dio());
  locator.registerLazySingleton<ApiClient>(() => ApiClient(locator<Dio>()));
  locator.registerLazySingleton<CountryRepo>(() => CountryRepo(locator<ApiClient>()));
}