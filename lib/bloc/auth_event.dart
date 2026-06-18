abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {
  AuthSignInRequested(this.email, this.password);
  final String email;
  final String password;
}

class AuthSignUpRequested extends AuthEvent {
  AuthSignUpRequested(this.email, this.password);
  final String email;
  final String password;
}

class AuthSignOutRequested extends AuthEvent {}