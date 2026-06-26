import 'package:freezed_annotation/freezed_annotation.dart';
import '../../database/app_database.dart';
import '../common/failures.dart';

part 'map_state.freezed.dart';

@freezed
abstract class MapState with _$MapState {
  const factory MapState.loading() = MapLoading;
  const factory MapState.loaded({required List<VisitedCountry> markers}) =
      MapLoaded;
  const factory MapState.error(Failure failure) = MapError;
}
