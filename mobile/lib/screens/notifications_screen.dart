import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../models/notification.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../utils/ui.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

/// Every message the notification service sent to this passenger.
///
/// Opening the list refreshes it from `GET /api/v1/notifications` and – once
/// the load succeeded – clears the unread badge of the home shell.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // `refreshNotifications` notifies every listener as soon as it starts, and
    // that may only happen once this route has finished building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refresh();
    });
  }

  Future<void> _refresh() async {
    final app = context.read<AppState>();
    await app.refreshNotifications();
    if (!mounted) return;
    if (app.notificationsError == null) {
      await app.markNotificationsRead();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final app = context.watch<AppState>();
    final items = app.notifications;

    final Widget body;
    if (app.notificationsLoading && items.isEmpty) {
      body = const LoadingView(message: 'নোটিফিকেশন আনা হচ্ছে...');
    } else if (app.notificationsError != null && items.isEmpty) {
      body = ErrorView(message: app.notificationsError!, onRetry: _refresh);
    } else if (items.isEmpty) {
      body = const EmptyView(
        icon: Icons.notifications_none,
        title: 'কোনো নোটিফিকেশন নেই',
        subtitle: 'বুকিং করলে বা বাতিল করলে এখানে আপডেট পাবেন।',
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildItem(theme, items[index]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('নোটিফিকেশন'),
        actions: <Widget>[
          IconButton(
            tooltip: 'রিফ্রেশ',
            onPressed: _refresh,
            icon: app.notificationsLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: body,
    );
  }

  Widget _buildItem(ThemeData theme, AppNotification item) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kBrandGreen.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                notificationIcon(item.channel),
                size: 21,
                color: kBrandGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (item.body.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF232823),
                      ),
                    ),
                  ],
                  if (item.sentAt != null) ...<Widget>[
                    const SizedBox(height: 6),
                    Text(
                      formatDateTime(item.sentAt!),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF6B726B),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
