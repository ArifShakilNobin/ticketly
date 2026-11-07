import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../state/app_state.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Launch screen: restores the cached session and routes to home or login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    final app = context.read<AppState>();
    try {
      await Future.wait<void>(<Future<void>>[
        app.bootstrap(),
        Future<void>.delayed(const Duration(milliseconds: 500)),
      ]);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
      return;
    }
    if (!mounted) return;
    final authenticated = app.status == SessionStatus.authenticated;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) =>
            authenticated ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }

  void _retry() {
    setState(() => _error = null);
    _resolve();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBrandGreen,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'টিকেটলি',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'বাংলাদেশের সব যানবাহনের টিকিট এক জায়গায়',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 34),
            if (_error == null)
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            else ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _retry,
                child: const Text(
                  'আবার চেষ্টা করুন',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
