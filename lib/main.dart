import 'package:flutter/material.dart';
import 'viewmodels/country_viewmodel.dart';
import 'views/list_screen.dart';
import 'views/detail_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Travel Journal',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final CountryViewModel vm = CountryViewModel();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: vm,
      builder: (context, child) {
        if (vm.selected == null) {
          return ListScreen(vm: vm);
        } else {
          return DetailScreen(vm: vm);
        }
      },
    );
  }
}