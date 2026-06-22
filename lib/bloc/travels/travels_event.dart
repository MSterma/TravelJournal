import 'package:freezed_annotation/freezed_annotation.dart';

part 'travels_event.freezed.dart';

@freezed
abstract class TravelsEvent with _$TravelsEvent {
  const factory TravelsEvent.loadData() = LoadTravelsData;
  const factory TravelsEvent.addTravel(String name) = AddTravelRequested;
  const factory TravelsEvent.selectTravel(int? travelId) = SelectTravel;
  const factory TravelsEvent.addNote({
    required String name,
    required double lat,
    required double lng,
    String? userNote,
    int? travelId,
    required List<String> photoPaths,
  }) = AddNoteRequested;
}
