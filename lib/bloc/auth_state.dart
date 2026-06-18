abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  AuthAuthenticated(this.userId);
  final String userId;
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  AuthError(this.message);
  final String message;
}