import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/app_snackbar.dart';
import 'home_screen.dart';
import 'register_screen.dart';

/// Sign in with a phone number (or e-mail) and password.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _identifier = TextEditingController();
  final TextEditingController _password = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  String? _identifierError;
  String? _passwordError;
  String? _formError;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validateIdentifier(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'ফোন নম্বর বা ইমেইল দিন';
    if (text.contains('@')) {
      final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
      if (!valid) return 'ইমেইল ঠিকানাটি সঠিক নয়';
      return null;
    }
    if (!RegExp(r'^01\d{9}$').hasMatch(text)) {
      return '১১ সংখ্যার মোবাইল নম্বর দিন (শুরু 01)';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'পাসওয়ার্ড দিন';
    if (text.length < 6) return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
    return null;
  }

  void _clearServerErrors() {
    if (_identifierError == null && _passwordError == null && _formError == null) {
      return;
    }
    setState(() {
      _identifierError = null;
      _passwordError = null;
      _formError = null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _identifierError = null;
      _passwordError = null;
      _formError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final app = context.read<AppState>();
    try {
      await app.login(
        identifier: _identifier.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      showSuccessSnack(context, 'স্বাগতম, ${app.user?.name ?? 'আবার আসুন'}!');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _identifierError = error.detailFor('identifier') ??
            error.detailFor('phone') ??
            (error.isUnauthorized ? error.message : null);
        _passwordError = error.detailFor('password');
        _formError = (_identifierError == null && _passwordError == null)
            ? error.message
            : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = errorMessageOf(error);
      });
    }
  }

  void _goToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const RegisterScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 54,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'টিকেটলিতে স্বাগতম',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'আপনার অ্যাকাউন্টে লগইন করুন',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: const Color(0xFF6B726B)),
                  ),
                  const SizedBox(height: 26),
                  TextFormField(
                    controller: _identifier,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'মোবাইল নম্বর বা ইমেইল',
                      hintText: '01XXXXXXXXX',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (_identifierError != null) return _identifierError;
                      return _validateIdentifier(value);
                    },
                    onChanged: (_) => _clearServerErrors(),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'পাসওয়ার্ড',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (_passwordError != null) return _passwordError;
                      return _validatePassword(value);
                    },
                    onChanged: (_) => _clearServerErrors(),
                  ),
                  if (_formError != null) ...<Widget>[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF0B4B4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Icon(
                            Icons.error_outline,
                            size: 18,
                            color: Color(0xFFC62828),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formError!,
                              style: const TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF8E2020),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('লগইন করুন'),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'নতুন ব্যবহারকারী?',
                        style: TextStyle(color: Color(0xFF6B726B)),
                      ),
                      TextButton(
                        onPressed: _submitting ? null : _goToRegister,
                        child: const Text('অ্যাকাউন্ট খুলুন'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
