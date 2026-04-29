import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/admin_coach_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/firebase_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _coachRegistration = false;
  String? _documentPath;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() => _error = null);
    try {
      if (_coachRegistration && (_documentPath == null || _documentPath!.isEmpty)) {
        setState(() => _error = 'Выберите документ тренера');
        return;
      }
      await ref.read(authControllerProvider).registerWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            fullName: _nameController.text.trim(),
          );
      if (_coachRegistration) {
        final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
        if (uid != null) {
          await ref.read(coachControllerProvider).submitCoachApplication(
                userId: uid,
                fullName: _nameController.text.trim(),
                email: _emailController.text.trim(),
                localFilePath: _documentPath!,
              );
        }
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'ФИО'),
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
            SwitchListTile(
              value: _coachRegistration,
              onChanged: (value) => setState(() => _coachRegistration = value),
              title: const Text('Регистрация как тренер'),
            ),
            if (_coachRegistration)
              ElevatedButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
                  if (result != null && result.files.single.path != null) {
                    setState(() => _documentPath = result.files.single.path);
                  }
                },
                child: Text(_documentPath == null ? 'Загрузить документ (PDF)' : 'Документ выбран'),
              ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _register, child: const Text('Зарегистрироваться')),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
