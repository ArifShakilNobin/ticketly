import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../state/app_state.dart';
import '../utils/format.dart';
import '../widgets/empty_view.dart';
import '../widgets/loading_view.dart';
import 'login_screen.dart';

/// The signed-in passenger: identity, account details and sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _muted = Color(0xFF6B726B);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final app = context.watch<AppState>();
    final user = app.user;

    if (user == null) {
      return app.status == SessionStatus.authenticated
          ? const LoadingView(message: 'প্রোফাইল আনা হচ্ছে...')
          : const EmptyView(
              icon: Icons.person_outline,
              title: 'প্রোফাইল দেখা যাচ্ছে না',
              subtitle: 'আবার লগইন করুন।',
            );
    }

    final initials = user.name.trim().isEmpty
        ? 'অ'
        : user.name.trim().characters.first.toUpperCase();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
      children: <Widget>[
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: <Widget>[
                CircleAvatar(
                  radius: 38,
                  backgroundColor: kBrandGreen,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.phone,
                  style: const TextStyle(fontSize: 14, color: _muted),
                ),
                if (user.email != null && user.email!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    user.email!,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
            child: Column(
              children: <Widget>[
                if (user.createdAt != null)
                  _row(
                    icon: Icons.event_available_outlined,
                    label: 'যোগদান',
                    value: formatDate(user.createdAt!),
                  ),
                _row(
                  icon: Icons.confirmation_number_outlined,
                  label: 'বুকিং',
                  value: 'বুকিং ট্যাব থেকে দেখুন',
                ),
                _row(icon: Icons.language, label: 'ভাষা', value: 'বাংলা'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),
        OutlinedButton.icon(
          onPressed: () => _logout(context),
          icon: const Icon(Icons.logout),
          label: const Text('লগআউট করুন'),
        ),
      ],
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 20, color: kBrandGreen),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      trailing: Text(
        value,
        textAlign: TextAlign.end,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: Color(0xFF232823),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('লগআউট?'),
        content: const Text('আবার ঢুকতে মোবাইল নম্বর ও পাসওয়ার্ড দিতে হবে।'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('থাকুক'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('লগআউট'),
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
}
