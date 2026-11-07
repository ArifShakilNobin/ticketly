import 'package:flutter/material.dart';

import '../services/api_client.dart';

/// Shows [error] the way the backend reported it – its `message` field.
void showErrorSnack(BuildContext context, Object error) {
  showInfoSnack(context, errorMessageOf(error));
}

/// Shows a short, floating message above the current screen.
void showInfoSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      dismissDirection: DismissDirection.horizontal,
    ),
  );
}

/// Shows a success message above the current screen.
void showSuccessSnack(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: const Color(0xFF127C56),
      dismissDirection: DismissDirection.horizontal,
    ),
  );
}
