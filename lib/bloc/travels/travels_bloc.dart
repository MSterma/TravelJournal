import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/local_repo.dart';
import '../../repositories/auth_repo.dart';
import '../common/failures.dart';
import 'travels_event.dart';
import 'travels_state.dart';

class TravelsBloc extends Bloc<TravelsEvent, TravelsState> {
  final LocalRepo localRepo;
  final AuthRepo authRepo;

  TravelsBloc({required this.localRepo, required this.authRepo})
      : super(const TravelsState.loading()) {
    on<LoadTravelsData>(_onLoadData);
    on<AddTravelRequested>(_onAddTravel);
    on<SelectTravel>(_onSelectTravel);
    on<AddNoteRequested>(_onAddNote);
  }

  Future<void> _onLoadData(
    LoadTravelsData event,
    Emitter<TravelsState> emit,
  ) async {
    final int? currentSelectedId = state is TravelsLoaded
        ? (state as TravelsLoaded).selectedTravelId
        : null;

    emit(const TravelsState.loading());
    await _fetchAndEmitData(emit, currentSelectedId);
  }

  Future<void> _onAddTravel(
    AddTravelRequested event,
    Emitter<TravelsState> emit,
  ) async {
    try {
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) return;

      await localRepo.addTravel(event.name, userId);
      add(const TravelsEvent.loadData());
    } catch (e) {
      emit(TravelsState.error(Failure.database(e.toString())));
    }
  }

  Future<void> _onSelectTravel(
    SelectTravel event,
    Emitter<TravelsState> emit,
  ) async {
    if (state is TravelsLoaded) {
      emit(const TravelsState.loading());
      await _fetchAndEmitData(emit, event.travelId);
    }
  }

  Future<void> _onAddNote(
    AddNoteRequested event,
    Emitter<TravelsState> emit,
  ) async {
    try {
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) return;

      await localRepo.addNoteWithPhotos(
        userId,
        event.lat,
        event.lng,
        event.name,
        event.userNote,
        event.travelId,
        event.photoPaths,
      );
      add(const TravelsEvent.loadData());
    } catch (e) {
      emit(TravelsState.error(Failure.database(e.toString())));
    }
  }

  Future<void> _fetchAndEmitData(
    Emitter<TravelsState> emit,
    int? selectedTravelId,
  ) async {
    try {
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) {
        emit(const TravelsState.error(Failure.auth("User not logged in")));
        return;
      }

      final travels = await localRepo.getTravels(userId);
      final allNotes = await localRepo.getAllNotes(userId);

      final timelineNotes = selectedTravelId == null
          ? <dynamic>[] // No notes if no travel selected according to existing UI logic
          : allNotes.where((n) => n.travelId == selectedTravelId).toList();

      final photosMap = <int, List<String>>{};
      final allPhotos = <String>[];

      for (final n in allNotes) {
        final p = await localRepo.getNotePhotos(n.id);
        photosMap[n.id] = p;
        if (selectedTravelId == null || n.travelId == selectedTravelId) {
          allPhotos.addAll(p);
        }
      }

      emit(TravelsState.loaded(
        travels: travels,
        allNotes: allNotes,
        timelineNotes: timelineNotes.cast(),
        notePhotos: photosMap,
        allTimelinePhotos: allPhotos,
        selectedTravelId: selectedTravelId,
      ));
    } catch (e) {
      emit(TravelsState.error(Failure.database(e.toString())));
    }
  }
}
