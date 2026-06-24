import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/common/failures.dart';
import '../../l10n/app_localizations.dart';
import '../widgets/common/loading_indicator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getErrorMessage(String code, AppLocalizations l10n) {
    switch (code) {
      case 'errorEmailInUse':
        return l10n.errorEmailInUse;
      case 'errorWeakPassword':
        return l10n.errorWeakPassword;
      case 'errorInvalidEmail':
        return l10n.errorInvalidEmail;
      default:
        return l10n.errorAuth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.signUp)),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            final failure = state.failure;
            if (failure is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_getErrorMessage(failure.message, l10n)),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else if (state is AuthAuthenticated) {
            Navigator.pop(context);
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
                                    AuthSignUpRequested(
                                      _emailController.text,
                                      _passwordController.text,
                                    ),
                                  );
                            },
                      child: Text(l10n.createAccount),
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
