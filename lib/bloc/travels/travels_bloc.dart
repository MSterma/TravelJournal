import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/local_repo.dart';
import '../../repositories/auth_repo.dart';
import '../../services/sync_service.dart';
import '../common/failures.dart';
import 'travels_event.dart';
import 'travels_state.dart';

class TravelsBloc extends Bloc<TravelsEvent, TravelsState> {
  TravelsBloc({
    required this.localRepo,
    required this.authRepo,
    required this.syncService,
  }) : super(const TravelsState.loading()) {
    on<LoadTravelsData>(_onLoadData);
    on<AddTravelRequested>(_onAddTravel);
    on<SelectTravel>(_onSelectTravel);
    on<AddNoteRequested>(_onAddNote);
    on<AddWantToGoPlaceRequested>(_onAddWantToGoPlace);
    on<TogglePlaceVisitedRequested>(_onTogglePlaceVisited);
  }

  final LocalRepo localRepo;
  final AuthRepo authRepo;
  final SyncService syncService;

  Future<void> _onLoadData(
    LoadTravelsData event,
    Emitter<TravelsState> emit,
  ) async {
    final int? currentSelectedId = state is TravelsLoaded
        ? (state as TravelsLoaded).selectedTravelId
        : null;

    final userId = await authRepo.getCurrentUserId();
    if (userId != null) {
      await syncService.performFullSync(userId);
    }

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
      syncService.syncLocalToCloud(userId);
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
      syncService.syncLocalToCloud(userId);
      add(const TravelsEvent.loadData());
    } catch (e) {
      emit(TravelsState.error(Failure.database(e.toString())));
    }
  }

  Future<void> _onAddWantToGoPlace(
    AddWantToGoPlaceRequested event,
    Emitter<TravelsState> emit,
  ) async {
    try {
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) return;

      await localRepo.addWantToGoPlace(event.name, event.lat, event.lng, userId);
      syncService.syncLocalToCloud(userId);
      add(const TravelsEvent.loadData());
    } catch (e) {
      emit(TravelsState.error(Failure.database(e.toString())));
    }
  }

  Future<void> _onTogglePlaceVisited(
    TogglePlaceVisitedRequested event,
    Emitter<TravelsState> emit,
  ) async {
    try {
      final userId = await authRepo.getCurrentUserId();
      await localRepo.togglePlaceVisited(event.id, event.isVisited);
      if (userId != null) {
        syncService.syncLocalToCloud(userId);
      }
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
      final wantToGoPlaces = await localRepo.getWantToGoPlaces(userId);

      final timelineNotes = selectedTravelId == null
          ? <dynamic>[]
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
        wantToGoPlaces: wantToGoPlaces,
        selectedTravelId: selectedTravelId,
      ));
    } catch (e) {
      emit(TravelsState.error(Failure.database(e.toString())));
    }
  }
}
