// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Travel Journal';

  @override
  String get countryList => 'Lista Krajów';

  @override
  String get country => 'Kraj';

  @override
  String get capital => 'Stolica';

  @override
  String get population => 'Populacja';

  @override
  String get region => 'Region';

  @override
  String get coordinates => 'Współrzędne';

  @override
  String get tryAgain => 'Spróbuj ponownie';

  @override
  String get noName => 'Brak nazwy';

  @override
  String get noCapital => 'Brak stolicy';

  @override
  String get noRegion => 'Brak regionu';
}
