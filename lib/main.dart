import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:travel_journal/services/notification_service.dart';
import 'package:travel_journal/services/location_service.dart';
import 'package:travel_journal/services/background_service.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'locator.dart';
import 'bloc/countries/country_bloc.dart';
import 'bloc/countries/country_event.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'bloc/travels/travels_bloc.dart';
import 'bloc/travels/travels_event.dart';
import 'views/auth/auth_wrapper.dart';
import 'theme.dart';
import 'repositories/country_repo.dart';
import 'repositories/local_repo.dart';
import 'repositories/auth_repo.dart';
import 'services/sync_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  setupLocator();
  final l10n = lookupAppLocalizations(WidgetsBinding.instance.platformDispatcher.locale);
  await locator<NotificationService>().init(
    channelName: l10n.proximityAlertsChannelName,
    channelDescription: l10n.proximityAlertsChannelDesc,
  );
  await initializeBackgroundService(l10n);
  await locator<LocationService>().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
              locator<AuthRepo>(),
              locator<SyncService>()
          )..add(AuthCheckRequested()),
        ),
        BlocProvider<CountryBloc>(
          create: (context) => CountryBloc(
            locator<CountryRepo>(),
            locator<AuthRepo>(),
            locator<SyncService>(),
          )..add(LoadCountries()),
        ),
        BlocProvider<TravelsBloc>(
          create: (context) => TravelsBloc(
            localRepo: locator<LocalRepo>(),
            authRepo: locator<AuthRepo>(),
            syncService: locator<SyncService>(),
          )..add(const TravelsEvent.loadData()),
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const AuthWrapper(),
      ),
    );
  }
}
