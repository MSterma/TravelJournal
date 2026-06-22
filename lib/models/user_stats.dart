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

  factory UserStats.empty() => const UserStats(
        totalPhotos: 0,
        todayPhotos: 0,
        totalNotes: 0,
        todayNotes: 0,
        totalCountries: 0,
        todayCountries: 0,
        last30DaysActivity: [],
        dailyAverage: 0.0,
        countriesThisMonth: [],
        totalTrips: 0,
        currentStreak: 0,
      );
}
