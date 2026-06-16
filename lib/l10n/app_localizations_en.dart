// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Travel Journal';

  @override
  String get countryList => 'Countries List';

  @override
  String get country => 'Country';

  @override
  String get capital => 'Capital';

  @override
  String get population => 'Population';

  @override
  String get region => 'Region';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noName => 'Not provided';

  @override
  String get noCapital => 'Not provided';

  @override
  String get noRegion => 'Not provided';

  @override
  String get navCountries => 'Countries';

  @override
  String get navMap => 'Map';

  @override
  String get navAccount => 'Account';

  @override
  String get search => 'Search country...';

  @override
  String get noResults => 'noResults';
}
