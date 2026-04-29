import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/user_role.dart';
import '../../providers/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Пользователь: ${session?.fullName ?? '-'}'),
            const SizedBox(height: 8),
            Text('Email: ${session?.email ?? '-'}'),
            const SizedBox(height: 8),
            Text('Роль: ${session?.role.name ?? '-'}'),
            const SizedBox(height: 8),
            Text('Статус: ${session?.approved == true ? 'активен' : 'ожидает подтверждения'}'),
            const SizedBox(height: 24),
            if (session?.role == UserRole.admin)
              const Text('Доступ администратора активен'),
            ElevatedButton(
              onPressed: () => ref.read(authControllerProvider).signOut(),
              child: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }
}
