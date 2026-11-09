import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'config/api_config.dart';
import 'config/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/booking_service.dart';
import 'services/notification_service.dart';
import 'services/search_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // `format.dart` renders dates with the `bn_BD` locale; the weekday and
  // month names only exist after the locale data has been loaded. When that
  // fails the formatters fall back to `en_US`, so this is best effort.
  try {
    await initializeDateFormatting('bn_BD');
  } catch (_) {
    // Keep going – every formatter in the app has a safe fallback.
  }

  runApp(const TicketlyApp());
}

/// Builds the single [AppState] shared by every screen.
AppState _createAppState() {
  final api = ApiClient(baseUrl: ApiConfig.baseUrl);
  return AppState(
    api: api,
    authService: AuthService(api),
    searchService: SearchService(api),
    bookingService: BookingService(api),
    notificationService: NotificationService(api),
  );
}

/// The Ticketly application: theme, session bootstrap and the splash screen
/// that routes to login or the home shell.
class TicketlyApp extends StatelessWidget {
  const TicketlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (_) => _createAppState(),
      child: MaterialApp(
        title: 'টিকেটলি',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
