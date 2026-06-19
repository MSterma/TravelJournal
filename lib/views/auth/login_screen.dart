import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/common/failures.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/loading_indicator.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.logIn)),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            final failure = state.failure;
            if (failure is AuthFailure) {
              final String code = failure.message;
              String msg;

              if (code == 'wrong-password' || code.contains('wrong-password')) {
                msg = l10n.errorWrongPassword;
              } else if (code == 'invalid-email' || code.contains('invalid-email')) {
                msg = l10n.errorInvalidEmail;
              } else if (code == 'user-not-found' || code.contains('user-not-found')) {
                msg = l10n.errorUserNotFound;
              } else if (code == 'invalid-credential' || code.contains('invalid-credential')) {
                msg = l10n.errorAuth;
              } else if (code == 'user-disabled' || code.contains('user-disabled')) {
                msg = l10n.errorUserNotFound;
              } else {
                msg = l10n.errorAuth;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l10n.email,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<AuthBloc>().add(
                                    AuthSignInRequested(
                                      _emailController.text,
                                      _passwordController.text,
                                    ),
                                  );
                            },
                      child: Text(l10n.logIn),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterScreen(),
                                ),
                              );
                            },
                      child: Text(l10n.noAccount, textAlign: TextAlign.center),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const AbsorbPointer(
                  child: Center(
                    child: LoadingIndicator(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
