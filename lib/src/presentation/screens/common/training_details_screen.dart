import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/athlete_providers.dart';
import '../../providers/auth_providers.dart';

class TrainingDetailsScreen extends ConsumerWidget {
  const TrainingDetailsScreen({required this.trainingId, super.key});

  final String trainingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Тренировка $trainingId')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(child: ListTile(title: Text('Разминка'), subtitle: Text('800 м'))),
          Card(child: ListTile(title: Text('Основная часть'), subtitle: Text('10 x 100 м'))),
          Card(child: ListTile(title: Text('Заминка'), subtitle: Text('400 м'))),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showResultDialog(context, ref),
        child: const Icon(Icons.flag),
      ),
    );
  }

  Future<void> _showResultDialog(BuildContext context, WidgetRef ref) async {
    final distanceController = TextEditingController();
    final timeController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Результат тренировки'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: distanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Дистанция (м)'),
              ),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Время'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Отмена')),
            ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Сохранить')),
          ],
        );
      },
    );
    if (result != true) return;
    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null) return;
    await ref.read(athleteControllerProvider).addTrainingResult(
          athleteUserId: user.id,
          trainingPlanId: trainingId,
          distanceMeters: double.tryParse(distanceController.text.trim()) ?? 0,
          timeValue: timeController.text.trim(),
        );
  }
}
