import 'package:freezed_annotation/freezed_annotation.dart';
import '../../database/app_database.dart';
import '../common/failures.dart';

part 'travels_state.freezed.dart';

@freezed
abstract class TravelsState with _$TravelsState {
  const factory TravelsState.loading() = TravelsLoading;
  const factory TravelsState.error(Failure failure) = TravelsError;
  const factory TravelsState.loaded({
    required List<Travel> travels,
    required List<Note> allNotes,
    required List<Note> timelineNotes,
    required Map<int, List<String>> notePhotos,
    required List<String> allTimelinePhotos,
    int? selectedTravelId,
  }) = TravelsLoaded;
}
