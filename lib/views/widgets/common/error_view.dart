import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16.0,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null)
              ElevatedButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? l10n.tryAgain),
              ),
          ],
        ),
      ),
    );
  }
}
