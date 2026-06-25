import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:travel_journal/repositories/auth_repo.dart';
import 'package:travel_journal/services/sync_service.dart';
import 'package:travel_journal/services/location_service.dart';
import 'package:travel_journal/services/notification_service.dart';
import 'database/app_database.dart';
import 'repositories/country_repo.dart';
import 'repositories/local_repo.dart';
import 'network/api_client.dart';
import 'package:dio/dio.dart';

final locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton<AppDatabase>(() => AppDatabase());
  locator.registerLazySingleton<LocalRepo>(() => LocalRepo(locator<AppDatabase>()));
  locator.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  locator.registerLazySingleton<AuthRepo>(() => AuthRepo(locator<FirebaseAuth>()));

  locator.registerLazySingleton<Dio>(() => Dio());
  locator.registerLazySingleton<ApiClient>(() => ApiClient(locator<Dio>()));
  locator.registerLazySingleton<CountryRepo>(() => CountryRepo(locator<ApiClient>()));

  locator.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  locator.registerLazySingleton<SyncService>(() => SyncService(locator<LocalRepo>(), locator<FirebaseFirestore>()));
  locator.registerLazySingleton<NotificationService>(() => NotificationService());
  locator.registerLazySingleton<LocationService>(() => LocationService(
    localRepo: locator<LocalRepo>(),
    authRepo: locator<AuthRepo>(),
    notificationService: locator<NotificationService>(),
  ));
}