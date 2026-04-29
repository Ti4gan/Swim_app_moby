import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_coach_providers.dart';
import '../../providers/auth_providers.dart';

class CoachAthletesScreen extends ConsumerWidget {
  const CoachAthletesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final athletes = ref.watch(coachAthletesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Спортсмены')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: athletes.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Пока нет спортсменов'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final athlete = items[index];
              return Card(
                child: ListTile(
                  title: Text(athlete.fullName),
                  subtitle: Text('Код входа: ${athlete.entryCode}'),
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

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Новый спортсмен'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'ФИО'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Создать'),
            ),
          ],
        );
      },
    );

    if (result == null || result.isEmpty) {
      return;
    }

    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null) {
      return;
    }

    final entryCode = await ref.read(coachControllerProvider).createAthlete(
          coachId: user.id,
          fullName: result,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Спортсмен создан. Код: $entryCode')),
      );
    }
  }
}
