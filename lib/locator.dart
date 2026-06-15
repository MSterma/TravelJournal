import 'package:get_it/get_it.dart';
import 'repositories/country_repo.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<CountryRepo>(() => CountryRepo());
}