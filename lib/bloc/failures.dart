import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
abstract class Failure with _$Failure {
  const factory Failure.database([@Default("Database Error") String message]) = DatabaseFailure;
  const factory Failure.network([@Default("Network Error") String message]) = NetworkFailure;
}