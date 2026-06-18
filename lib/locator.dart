import 'package:get_it/get_it.dart';
import 'database/app_database.dart';
import 'repositories/country_repo.dart';
import 'repositories/local_repo.dart';
import 'network/api_client.dart';
import 'package:dio/dio.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());
  locator.registerLazySingleton<LocalRepo>(() => LocalRepo(locator<AppDatabase>()));

  locator.registerLazySingleton<Dio>(() => Dio());
  locator.registerLazySingleton<ApiClient>(() => ApiClient(locator<Dio>()));
  locator.registerLazySingleton<CountryRepo>(() => CountryRepo(locator<ApiClient>()));
}