import 'package:flutter/material.dart';

/// Error state with an optional retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.title = 'কিছু সমস্যা হয়েছে',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_outlined,
              size: 54,
              color: Color(0xFF9AA39A),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFF6B726B)),
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('আবার চেষ্টা করুন'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
