import 'package:freezed_annotation/freezed_annotation.dart';
import '../../models/country.dart';
import '../common/failures.dart';

part 'country_details_state.freezed.dart';

@freezed
abstract class CountryDetailsState with _$CountryDetailsState {
  const factory CountryDetailsState.loading() = DetailsLoading;
  const factory CountryDetailsState.loaded({
    required bool isVisited,
    required List<String> photos,
    Country? country,
    Failure? failure,
  }) = DetailsLoaded;
}
