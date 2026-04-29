import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_coach_providers.dart';

class AdminCoachApprovalScreen extends ConsumerWidget {
  const AdminCoachApprovalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applications = ref.watch(pendingCoachApplicationsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Подтверждение тренеров')),
      body: applications.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Нет заявок'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: ListTile(
                  title: Text(item.fullName),
                  subtitle: Text(item.email),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          ref.read(adminControllerProvider).rejectCoach(item.id, item.userId);
                        },
                        child: const Text('Отклонить'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(adminControllerProvider).approveCoach(item.id, item.userId);
                        },
                        child: const Text('Одобрить'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
      ),
    );
  }
}
