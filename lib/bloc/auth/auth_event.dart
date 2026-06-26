import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_event.freezed.dart';

@freezed
abstract class AuthEvent with _$AuthEvent {
  const factory AuthEvent.checkRequested() = AuthCheckRequested;
  const factory AuthEvent.signInRequested(String email, String password) =
      AuthSignInRequested;
  const factory AuthEvent.signUpRequested(String email, String password) =
      AuthSignUpRequested;
  const factory AuthEvent.signOutRequested() = AuthSignOutRequested;
}
