import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../utils/ui.dart';
import '../widgets/empty_view.dart';
import '../widgets/error_view.dart';
import '../widgets/loading_view.dart';

/// Every notification pushed by the backend, newest first.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final app = context.read<AppState>();
    await app.refreshNotifications();
    if (!mounted) return;
    // Opening the list is the natural "I have seen these" signal.
    await app.markNotificationsRead();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('নোটিফিকেশন')),
      body: SafeArea(child: _buildBody(app, theme)),
    );
  }

  Widget _buildBody(AppState app, ThemeData theme) {
    if (app.notificationsLoading && app.notifications.isEmpty) {
      return const LoadingView(message: 'নোটিফিকেশন আনা হচ্ছে...');
    }
    if (app.notificationsError != null && app.notifications.isEmpty) {
      return ErrorView(
        message: app.notificationsError!,
        onRetry: () => context.read<AppState>().refreshNotifications(),
      );
    }
    if (app.notifications.isEmpty) {
      return const EmptyView(
        icon: Icons.notifications_none,
        title: 'কোনো নোটিফিকেশন নেই',
        subtitle: 'বুকিং বা অফার সম্পর্কে খবর এখানে জানানো হবে।',
      );
    }

    final items = List<AppNotification>.of(app.notifications)
      ..sort((a, b) {
        final aTime = a.sentAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.sentAt?.millisecondsSinceEpoch ?? 0;
        return bTime.compareTo(aTime);
      });

    return RefreshIndicator(
      onRefresh: () => context.read<AppState>().refreshNotifications(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          final unread = !item.isRead;
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: unread
                          ? const Color(0xFF00674B).withValues(alpha: 0.10)
                          : const Color(0xFFEDEFEC),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      notificationIcon(item.channel),
                      size: 20,
                      color: unread
                          ? const Color(0xFF00674B)
                          : const Color(0xFF6B726B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                item.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight:
                                      unread ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ),
                            if (unread)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE30613),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.body,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4A524A),
                          ),
                        ),
                        if (item.sentAt != null) ...<Widget>[
                          const SizedBox(height: 6),
                          Text(
                            formatDateTime(item.sentAt!),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF8B948B),
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
        },
      ),
    );
  }
}
