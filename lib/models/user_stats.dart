import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_stats.freezed.dart';

@freezed
abstract class UserStats with _$UserStats {
  const factory UserStats({
    required int totalPhotos,
    required int todayPhotos,
    required int totalNotes,
    required int todayNotes,
    required int totalCountries,
    required int todayCountries,
    required List<int> last30DaysActivity,
    required double dailyAverage,
    required List<String> countriesThisMonth,
    required int totalTrips,
    required int currentStreak,
  }) = _UserStats;
}
