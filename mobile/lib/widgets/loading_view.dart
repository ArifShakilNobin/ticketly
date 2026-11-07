import 'package:flutter/material.dart';

/// Full screen spinner with an optional caption.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message = 'লোড হচ্ছে...'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF6B726B)),
          ),
        ],
      ),
    );
  }
}
