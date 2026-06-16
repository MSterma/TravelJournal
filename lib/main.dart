import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locator.dart';
import 'bloc/country_bloc.dart';
import 'bloc/country_event.dart';
import 'views/main_screen.dart';
import 'theme.dart';

void main() {
  setupLocator();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Journal',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: BlocProvider(
        create: (context) => CountryBloc(locator())..add(LoadCountries()),
        child: const MainScreen(),
      ),
    );
  }
}