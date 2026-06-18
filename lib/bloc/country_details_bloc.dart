import 'package:flutter_bloc/flutter_bloc.dart';
import '../locator.dart';
import '../services/sync_service.dart';
import 'country_details_event.dart';
import 'country_details_state.dart';
import 'failures.dart';
import '../repositories/local_repo.dart';
import '../repositories/auth_repo.dart';

class CountryDetailsBloc extends Bloc<CountryDetailsEvent, CountryDetailsState> {
  CountryDetailsBloc(this.localRepo, this.authRepo) : super(DetailsLoading()) {
    on<LoadDetails>(_onLoadDetails);
    on<MarkCountryVisited>(_onMarkVisited);
    on<AddCountryPhoto>(_onAddPhoto);
  }

  final LocalRepo localRepo;
  final AuthRepo authRepo;

  Future<void> _onLoadDetails(LoadDetails event, Emitter<CountryDetailsState> emit) async {
    emit(DetailsLoading());
    try {
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) return;

      final isVisited = await localRepo.checkVisited(event.countryName, userId);
      final photos = await localRepo.getPhotos(event.countryName, userId);
      emit(DetailsLoaded(isVisited: isVisited, photos: photos));
    } catch (e) {
      emit(DetailsLoaded(isVisited: false, photos: [], failure: DatabaseFailure("Failed to load details")));
    }
  }

  Future<void> _onMarkVisited(MarkCountryVisited event, Emitter<CountryDetailsState> emit) async {
    if (state is DetailsLoaded) {
      final currentState = state as DetailsLoaded;
      try {
        final userId = await authRepo.getCurrentUserId();
        await localRepo.markVisited(event.countryName, userId!, event.lat, event.lng);
        locator<SyncService>().syncLocalToCloud(userId);
        emit(currentState.copyWith(isVisited: true, failure: null));
      } catch (e) {
        emit(currentState.copyWith(failure: DatabaseFailure("Failed to mark as visited")));
      }
    }
  }
  Future<void> _onAddPhoto(AddCountryPhoto event, Emitter<CountryDetailsState> emit) async {
    if (state is DetailsLoaded) {
      final currentState = state as DetailsLoaded;
      try {
        final userId = await authRepo.getCurrentUserId();
        await localRepo.addPhoto(event.countryName, event.imagePath, userId!);
        final newPhotos = List<String>.from(currentState.photos)..add(event.imagePath);
        emit(currentState.copyWith(photos: newPhotos, failure: null));
      } catch (e) {
        emit(currentState.copyWith(failure: DatabaseFailure("Failed to add photo")));
      }
    }
  }
}