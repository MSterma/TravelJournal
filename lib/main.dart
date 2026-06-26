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

  try {
    // 1. Safe dotenv load
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint("Warning: .env load failed: $e");
    }

    // 2. Initialize Firebase only if not already ready
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // 3. ALWAYS setup locator before running the app
    setupLocator();

    runApp(const MyApp());

    // Non-blocking services initialization
    _initializeServices();
  } catch (e) {
    debugPrint("Critical initialization error: $e");

    // Emergency setup: try to setup locator if not already registered
    try {
      if (!locator.isRegistered<AuthRepo>()) {
        setupLocator();
      }
    } catch (_) {}

    // Show error on screen instead of grey background to help debugging
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SelectableText(
                "Application Start Error:\n$e",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeServices() async {
  try {
    final l10n = lookupAppLocalizations(
      WidgetsBinding.instance.platformDispatcher.locale,
    );

    await locator<NotificationService>().init(
      channelName: l10n.proximityAlertsChannelName,
      channelDescription: l10n.proximityAlertsChannelDesc,
    );

    await initializeBackgroundService(l10n);
    await locator<LocationService>().init();
  } catch (e) {
    debugPrint("Service initialization error: $e");
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) =>
              AuthBloc(locator<AuthRepo>(), locator<SyncService>())
                ..add(AuthCheckRequested()),
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
