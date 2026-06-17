import 'failures.dart';

abstract class CountryDetailsState {}

class DetailsLoading extends CountryDetailsState {}

class DetailsLoaded extends CountryDetailsState {
  DetailsLoaded({
    required this.isVisited,
    required this.photos,
    this.failure,
  });

  final bool isVisited;
  final List<String> photos;
  final Failure? failure;

  DetailsLoaded copyWith({
    bool? isVisited,
    List<String>? photos,
    Failure? failure,
  }) {
    return DetailsLoaded(
      isVisited: isVisited ?? this.isVisited,
      photos: photos ?? this.photos,
      failure: failure,
    );
  }
}