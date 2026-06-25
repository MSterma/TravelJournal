class AppConstants {
  // Proximity Notification Settings
  static const double proximityDistanceThreshold = 200.0;
  static const int notificationIntervalHours = 1;
  static const int proximityNotificationIdOffset = 1000;
  
  // Location Settings
  static const int locationDistanceFilter = 10;
  
  // Database/Firestore Constants
  static const String colUsers = 'users';
  static const String colVisited = 'visited';
  static const String colTravels = 'travels';
  static const String colNotes = 'notes';
  static const String colWantToGo = 'want_to_go';
  
  // Placeholder Constants
  static const String photoPlaceholder = '__PLACEHOLDER__';
}
