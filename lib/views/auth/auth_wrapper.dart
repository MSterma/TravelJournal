import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../main/main_screen.dart';
import '../widgets/loading_indicator.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        // 1. Always allow moving away from the very first Initial state
        if (previous is AuthInitial) return true;

        // 2. Only rebuild the tree when switching between core states: 
        // authenticated and non-authenticated (Login).
        // We stay on the current screen during Loading or Error transitions
        // to prevent widget destruction and SnackBar loss.
        final bool wasAuth = previous is AuthAuthenticated;
        final bool isAuth = current is AuthAuthenticated;

        return wasAuth != isAuth;
      },
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const MainScreen();
        } else if (state is AuthInitial) {
          return const Scaffold(
            body: LoadingIndicator(),
          );
        }

        // For Unauthenticated, Loading, and Error - show LoginScreen.
        // LoginScreen handles its own internal loading and error UI.
        return const LoginScreen();
      },
    );
  }
}
