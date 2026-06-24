import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/local_repo.dart';
import '../../repositories/auth_repo.dart';
import 'map_event.dart';
import 'map_state.dart';
import '../common/failures.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc(this.localRepo, this.authRepo) : super(const MapState.loading()) {
    on<LoadMarkers>(_onLoadMarkers);
  }

  final LocalRepo localRepo;
  final AuthRepo authRepo;

  Future<void> _onLoadMarkers(
    LoadMarkers event,
    Emitter<MapState> emit,
  ) async {
    emit(const MapState.loading());
    try {
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) {
        emit(const MapState.error(Failure.auth("User not logged in")));
        return;
      }

      final markers = await localRepo.getVisitedWithCoords(userId);
      emit(MapState.loaded(markers: markers));
    } catch (e) {
      emit(MapState.error(Failure.database(e.toString())));
    }
  }
}
