import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../repositories/auth_repo.dart';
import '../services/sync_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this.authRepo, this.syncService) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onAuthSignInRequested);
    on<AuthSignUpRequested>(_onAuthSignUpRequested);
    on<AuthSignOutRequested>(_onAuthSignOutRequested);
  }

  final AuthRepo authRepo;
  final SyncService syncService;

  Future<void> _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async {
    final userId = await authRepo.getCurrentUserId();
    if (userId != null) {
      emit(AuthAuthenticated(userId));
      syncService.syncCloudToLocal(userId).then((_) {
        syncService.syncLocalToCloud(userId);
      });
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthSignInRequested(AuthSignInRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepo.signIn(event.email, event.password);
      final userId = await authRepo.getCurrentUserId();
      emit(AuthAuthenticated(userId!));

      syncService.syncCloudToLocal(userId).then((_) {
        syncService.syncLocalToCloud(userId);
      });
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthSignUpRequested(AuthSignUpRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await authRepo.signUp(event.email, event.password);
      final userId = await authRepo.getCurrentUserId();
      emit(AuthAuthenticated(userId!));

      syncService.syncCloudToLocal(userId).then((_) {
        syncService.syncLocalToCloud(userId);
      });
    } catch (e) {
      emit(AuthError(e.toString()));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthSignOutRequested(AuthSignOutRequested event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await authRepo.signOut();
    emit(AuthUnauthenticated());
  }
}