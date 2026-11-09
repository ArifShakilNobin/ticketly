import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ticketly/screens/notifications_screen.dart';
import 'package:ticketly/services/api_client.dart';
import 'package:ticketly/services/auth_service.dart';
import 'package:ticketly/services/booking_service.dart';
import 'package:ticketly/services/notification_service.dart';
import 'package:ticketly/services/search_service.dart';
import 'package:ticketly/state/app_state.dart';

AppState _buildAppState() {
  final api = ApiClient(baseUrl: 'http://localhost:8080');
  return AppState(
    api: api,
    authService: AuthService(api),
    searchService: SearchService(api),
    bookingService: BookingService(api),
    notificationService: NotificationService(api),
  );
}

/// Stands in for the home shell, which also listens to [AppState] – exactly
/// the constellation that used to blow up when the screen refreshed from
/// `initState` instead of after the first frame.
class _Shell extends StatelessWidget {
  const _Shell();

  @override
  Widget build(BuildContext context) {
    final unread = context.select<AppState, int>((state) => state.unreadCount);
    return Column(
      children: <Widget>[
        Text('unread:$unread', textDirection: TextDirection.ltr),
        Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const NotificationsScreen(),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ],
    );
  }
}

void main() {
  testWidgets('the shell keeps working while notifications load', (
    tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>(
        create: (_) => _buildAppState(),
        child: MaterialApp(home: Scaffold(body: _Shell())),
      ),
    );
    expect(find.text('unread:0'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pump(); // start the route transition
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(); // first frame of the screen -> schedules the refresh
    await tester.pump(const Duration(milliseconds: 350)); // refresh settles

    expect(tester.takeException(), isNull);
    expect(find.text('নোটিফিকেশন'), findsOneWidget);
  });
}
