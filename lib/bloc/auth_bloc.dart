import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../repositories/auth_repo.dart';
import '../services/sync_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.authRepo, this.syncService) : super(const AuthState.initial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
  }

  final AuthRepo authRepo;
  final SyncService syncService;

  void _runSync(String userId) {
    syncService.syncCloudToLocal(userId).then((_) {
      syncService.syncLocalToCloud(userId);
    });
  }

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final userId = await authRepo.getCurrentUserId();
    if (userId != null) {
      emit(AuthState.authenticated(userId));
      _runSync(userId);
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onAuthSignInRequested(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      await authRepo.signIn(event.email, event.password);
      final userId = await authRepo.getCurrentUserId();
      emit(AuthState.authenticated(userId!));
      _runSync(userId);
    } catch (e) {
      emit(AuthState.error(e.toString()));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onAuthSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    try {
      await authRepo.signUp(event.email, event.password);
      final userId = await authRepo.getCurrentUserId();
      emit(AuthState.authenticated(userId!));
      _runSync(userId);
    } catch (e) {
      emit(AuthState.error(e.toString()));
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> _onAuthSignOutRequested(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    await authRepo.signOut();
    emit(const AuthState.unauthenticated());
  }
}