import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';

/// Account summary and sign out. Embedded in the home shell.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('লগআউট করবেন?'),
        content: const Text('পরে আবার লগইন করতে হবে।'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('না'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('হ্যাঁ, লগআউট'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final app = context.read<AppState>();
    await app.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppState>();
    final user = app.user;

    return RefreshIndicator(
      onRefresh: () => Future.wait(<Future<void>>[
        app.refreshOffers(),
        app.refreshNotifications(),
      ]),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 34,
                      backgroundColor:
                          kBrandGreen.withValues(alpha: 0.12),
                      child: Text(
                        (user?.name.isNotEmpty ?? false)
                            ? user!.name.characters.first.toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: kBrandGreen,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'অতিথি ব্যবহারকারী',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.phone ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B726B),
                      ),
                    ),
                    if (user?.email != null &&
                        user!.email!.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 2),
                      Text(
                        user.email!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B726B),
                        ),
                      ),
                    ],
                    if (user?.createdAt != null) ...<Widget>[
                      const SizedBox(height: 10),
                      Text(
                        'সদস্য: ${formatDate(user!.createdAt!)} থেকে',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF8B948B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Column(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(
                      Icons.confirmation_number_outlined,
                      color: kBrandGreen,
                    ),
                    title: const Text('আমার বুকিং দেখুন'),
                    subtitle: const Text('সব টিকিট ও স্ট্যাটাস'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => Scaffold(
                          appBar: AppBar(title: const Text('আমার বুকিং')),
                          body: const MyBookingsScreen(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'টিকেটলি সম্পর্কে',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'বাংলাদেশের ট্রেন, বাস, লঞ্চ ও ফ্লাইটের ভাড়া '
                      'একসাথে খুঁজে সাশ্রয়ী মূল্যে টিকিট কাটার '
                      'প্ল্যাটফর্ম।',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF4A524A),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'সংস্করণ 0.1.0 · ডেমো ব্যাকএন্ড',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8B948B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _logout(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: kBrandRed,
                side: const BorderSide(color: kBrandRed),
              ),
              icon: const Icon(Icons.logout),
              label: const Text('লগআউট'),
            ),
          ],
        ),
      ),
    );
  }
}
