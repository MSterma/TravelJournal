import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../countries/countries_tab.dart';
import '../map/map_screen.dart';
import '../travels/travels_screen.dart';
import 'account_screen.dart';
import '../../locator.dart';
import '../../services/notification_service.dart';
import '../../repositories/auth_repo.dart';
import '../widgets/note_form_modal.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/travels/travels_bloc.dart';
import '../../bloc/travels/travels_event.dart';
import '../../services/location_service.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _notificationSubscription = locator<NotificationService>().onNotificationClick.listen(_handleNotificationPayload);
    _initGlobalLocationTracking();
  }

  Future<void> _initGlobalLocationTracking() async {
    final locationService = locator<LocationService>();
    final hasPermission = await locationService.handlePermission();
    if (hasPermission) {
      debugPrint('MainScreen: Starting global location tracking');
      locationService.startTracking();
    } else {
      debugPrint('MainScreen: Location permission not granted for global tracking');
    }
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _handleNotificationPayload(Map<String, dynamic> data) async {
    if (data['type'] == 'proximity_note') {
      setState(() {
        _currentIndex = 2; // Travels tab
      });

      final userId = await locator<AuthRepo>().getCurrentUserId();
      if (userId != null && mounted) {
        NoteFormModal.show(
          context,
          userId: userId,
          lat: data['lat'],
          lng: data['lng'],
          onSuccess: () {
            if (mounted) {
              context.read<TravelsBloc>().add(const TravelsEvent.loadData());
            }
          },
        );
      }
    }
  }

  final List<Widget> _screens = [
    const CountriesTab(),
    const MapScreen(),
    const TravelsScreen(),
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
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.public),
            label: l10n?.navCountries ?? 'Countries',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: l10n?.navMap ?? 'Map',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.timeline),
            label: l10n?.navTravels ?? 'Travels',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: l10n?.navAccount ?? 'Account',
          ),
        ],
      ),
    );
  }
}