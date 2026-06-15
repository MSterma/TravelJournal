import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'locator.dart';
import 'bloc/country_bloc.dart';
import 'bloc/country_event.dart';
import 'views/main_screen.dart';

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
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue)),
      home: BlocProvider(
        create: (context) => CountryBloc(locator())..add(LoadCountries()),
        child: const MainScreen(),
      ),
    );
  }
}