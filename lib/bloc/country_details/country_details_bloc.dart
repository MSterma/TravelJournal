import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/sync_service.dart';
import '../../repositories/country_repo.dart';
import '../../models/country.dart';
import 'country_details_event.dart';
import 'country_details_state.dart';
import '../common/failures.dart';
import '../../repositories/local_repo.dart';
import '../../repositories/auth_repo.dart';

class CountryDetailsBloc
    extends Bloc<CountryDetailsEvent, CountryDetailsState> {
  CountryDetailsBloc(
    this.localRepo,
    this.authRepo,
    this.syncService,
    this.countryRepo,
  ) : super(const CountryDetailsState.loading()) {
    on<LoadDetails>(_onLoadDetails);
    on<MarkCountryVisited>(_onMarkVisited);
    on<AddCountryPhoto>(_onAddPhoto);
  }

  final LocalRepo localRepo;
  final AuthRepo authRepo;
  final SyncService syncService;
  final CountryRepo countryRepo;

  Future<void> _onLoadDetails(
    LoadDetails event,
    Emitter<CountryDetailsState> emit,
  ) async {
    emit(const CountryDetailsState.loading());
    try {
      final userId = await authRepo.getCurrentUserId();
      if (userId == null) return;

      Country? country = event.country;
      if (country == null) {
        final countries = await countryRepo.getCountries(
          query: event.countryName,
        );
        if (countries.isNotEmpty) {
          country = countries.first;
        }
      }

      final isVisited = await localRepo.checkVisited(event.countryName, userId);
      final photos = await localRepo.getPhotos(event.countryName, userId);
      emit(
        CountryDetailsState.loaded(
          isVisited: isVisited,
          photos: photos,
          country: country,
        ),
      );
    } catch (e) {
      emit(
        CountryDetailsState.loaded(
          isVisited: false,
          photos: [],
          failure: const DatabaseFailure("Failed to load details"),
        ),
      );
    }
  }

  Future<void> _onMarkVisited(
    MarkCountryVisited event,
    Emitter<CountryDetailsState> emit,
  ) async {
    if (state case final DetailsLoaded loadedState) {
      try {
        final userId = await authRepo.getCurrentUserId();
        await localRepo.markVisited(
          event.countryName,
          userId!,
          event.lat,
          event.lng,
        );
        syncService.syncLocalToCloud(userId);
        emit(loadedState.copyWith(isVisited: true, failure: null));
      } catch (e) {
        emit(
          loadedState.copyWith(
            failure: const DatabaseFailure("Failed to mark as visited"),
          ),
        );
      }
    }
  }

  Future<void> _onAddPhoto(
    AddCountryPhoto event,
    Emitter<CountryDetailsState> emit,
  ) async {
    if (state case final DetailsLoaded loadedState) {
      try {
        final userId = await authRepo.getCurrentUserId();
        await localRepo.addPhoto(event.countryName, event.imagePath, userId!);

        emit(
          loadedState.copyWith(
            photos: [...loadedState.photos, event.imagePath],
            failure: null,
          ),
        );
      } catch (e) {
        emit(
          loadedState.copyWith(
            failure: const DatabaseFailure("Failed to add photo"),
          ),
        );
      }
    }
  }
}
