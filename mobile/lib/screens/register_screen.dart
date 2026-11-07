import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../state/app_state.dart';
import '../widgets/app_snackbar.dart';
import 'home_screen.dart';

/// Create a new Ticketly account.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  Map<String, String> _serverErrors = const <String, String>{};
  String? _formError;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _serverErrorFor(String field) => _serverErrors[field];

  String? _validateName(String? value) {
    final server = _serverErrorFor('name');
    if (server != null) return server;
    if ((value ?? '').trim().isEmpty) return 'আপনার নাম লিখুন';
    return null;
  }

  String? _validatePhone(String? value) {
    final server = _serverErrorFor('phone');
    if (server != null) return server;
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'মোবাইল নম্বর দিন';
    if (!RegExp(r'^01\d{9}$').hasMatch(text)) {
      return '১১ সংখ্যার মোবাইল নম্বর দিন (শুরু 01)';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final server = _serverErrorFor('email');
    if (server != null) return server;
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'ইমেইল ঠিকানাটি সঠিক নয়';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final server = _serverErrorFor('password');
    if (server != null) return server;
    final text = value ?? '';
    if (text.isEmpty) return 'পাসওয়ার্ড দিন';
    if (text.length < 6) return 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে';
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _password.text) return 'পাসওয়ার্ড দুটি মিলছে না';
    return null;
  }

  void _clearServerErrors() {
    if (_serverErrors.isEmpty && _formError == null) return;
    setState(() {
      _serverErrors = const <String, String>{};
      _formError = null;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _serverErrors = const <String, String>{};
      _formError = null;
    });
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final app = context.read<AppState>();
    try {
      await app.register(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      showSuccessSnack(context, 'অ্যাকাউন্ট তৈরি হয়েছে!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _serverErrors = error.details;
        _formError = error.details.isEmpty ? error.message : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _formError = errorMessageOf(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('অ্যাকাউন্ট খুলুন')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'নতুন ব্যবহারকারী',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  'নাম, মোবাইল নম্বর ও পাসওয়ার্ড দিয়ে রেজিস্টার করুন',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: const Color(0xFF6B726B)),
                ),
                const SizedBox(height: 22),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'পুরো নাম',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: _validateName,
                  onChanged: (_) => _clearServerErrors(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  maxLength: 11,
                  decoration: const InputDecoration(
                    labelText: 'মোবাইল নম্বর',
                    hintText: '01XXXXXXXXX',
                    prefixIcon: Icon(Icons.phone_iphone),
                    counterText: '',
                  ),
                  validator: _validatePhone,
                  onChanged: (_) => _clearServerErrors(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'ইমেইল (ঐচ্ছিক)',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: _validateEmail,
                  onChanged: (_) => _clearServerErrors(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.next,
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
                  validator: _validatePassword,
                  onChanged: (_) => _clearServerErrors(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _confirm,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    labelText: 'পাসওয়ার্ড আবার লিখুন',
                    prefixIcon: Icon(Icons.lock_reset_outlined),
                  ),
                  validator: _validateConfirm,
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
                      : const Text('রেজিস্টার করুন'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('ইতিমধ্যে অ্যাকাউন্ট আছে? লগইন করুন'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
