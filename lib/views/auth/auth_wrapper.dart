import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../main/main_screen.dart';
import '../widgets/common/loading_indicator.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (previous, current) {
        if (previous is AuthInitial) return true;
        final bool wasAuth = previous is AuthAuthenticated;
        final bool isAuth = current is AuthAuthenticated;

        return wasAuth != isAuth;
      },
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          return const MainScreen();
        } else if (state is AuthInitial) {
          return const Scaffold(body: LoadingIndicator());
        }
        return const LoginScreen();
      },
    );
  }
}
