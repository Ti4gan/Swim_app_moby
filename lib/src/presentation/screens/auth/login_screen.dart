import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/athlete_providers.dart';
import '../../providers/auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _entryCodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _smsController = TextEditingController();
  bool _athleteCodeMode = false;
  bool _phoneMode = false;
  String? _verificationId;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entryCodeController.dispose();
    _phoneController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() => _error = null);
    try {
      await ref
          .read(authControllerProvider)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _signInByCode() async {
    setState(() => _error = null);
    try {
      await ref
          .read(athleteControllerProvider)
          .signInWithEntryCode(_entryCodeController.text.trim());
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _sendPhoneCode() async {
    setState(() => _error = null);
    try {
      final id = await ref
          .read(authControllerProvider)
          .startPhoneSignIn(phoneNumber: _phoneController.text.trim());
      setState(() => _verificationId = id);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _verifyPhoneCode() async {
    setState(() => _error = null);
    try {
      final verificationId = _verificationId;
      if (verificationId == null) {
        setState(() => _error = 'Сначала отправьте SMS-код');
        return;
      }
      await ref
          .read(authControllerProvider)
          .verifyPhoneCode(
            verificationId: verificationId,
            smsCode: _smsController.text.trim(),
          );
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              value: _athleteCodeMode,
              onChanged: (value) => setState(() {
                _athleteCodeMode = value;
                if (value) _phoneMode = false;
              }),
              title: const Text('Вход спортсмена по коду'),
            ),
            SwitchListTile(
              value: _phoneMode,
              onChanged: (value) => setState(() {
                _phoneMode = value;
                if (value) _athleteCodeMode = false;
              }),
              title: const Text('Вход по телефону'),
            ),
            if (!_athleteCodeMode && !_phoneMode) ...[
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль'),
              ),
            ] else if (_athleteCodeMode) ...[
              TextField(
                controller: _entryCodeController,
                decoration: const InputDecoration(labelText: 'Код спортсмена'),
              ),
            ] else ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Телефон (+375...)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _smsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'SMS-код'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _sendPhoneCode,
                    child: const Text('Код'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _athleteCodeMode
                  ? _signInByCode
                  : _phoneMode
                  ? _verifyPhoneCode
                  : _signIn,
              child: const Text('Войти'),
            ),
            TextButton(
              onPressed: () => context.push('/register'),
              child: const Text('Создать аккаунт'),
            ),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
