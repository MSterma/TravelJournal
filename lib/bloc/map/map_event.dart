import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_event.freezed.dart';

@freezed
abstract class MapEvent with _$MapEvent {
  const factory MapEvent.loadMarkers() = LoadMarkers;
}
