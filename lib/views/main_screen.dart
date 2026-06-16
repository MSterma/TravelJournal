import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'countries_tab.dart';
import 'map_screen.dart';
import 'account_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const CountriesTab(),
    const MapScreen(),
    const AccountScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items:  [
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: l10n?.navCountries??'Countries',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: l10n?.navMap??'Map',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n?.navAccount??'Account',
          ),
        ],
      ),
    );
  }
}