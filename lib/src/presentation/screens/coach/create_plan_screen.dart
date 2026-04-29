import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/admin_coach_providers.dart';
import '../../providers/auth_providers.dart';

class CreatePlanScreen extends ConsumerStatefulWidget {
  const CreatePlanScreen({super.key});

  @override
  ConsumerState<CreatePlanScreen> createState() => _CreatePlanScreenState();
}

class _CreatePlanScreenState extends ConsumerState<CreatePlanScreen> {
  final _titleController = TextEditingController();
  final _athleteIdController = TextEditingController();
  final _distanceController = TextEditingController();
  final _targetTimeController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _athleteIdController.dispose();
    _distanceController.dispose();
    _targetTimeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = ref.read(authSessionProvider).valueOrNull;
    if (user == null) {
      return;
    }
    await ref.read(coachControllerProvider).createTrainingPlan(
          coachId: user.id,
          athleteId: _athleteIdController.text.trim(),
          title: _titleController.text.trim(),
          distanceMeters: double.tryParse(_distanceController.text.trim()) ?? 0,
          targetTime: _targetTimeController.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('План сохранен')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Создание плана')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Название плана')),
          const SizedBox(height: 12),
          TextField(controller: _athleteIdController, decoration: const InputDecoration(labelText: 'ID спортсмена')),
          const SizedBox(height: 12),
          TextField(
            controller: _distanceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Дистанция (м)'),
          ),
          const SizedBox(height: 12),
          TextField(controller: _targetTimeController, decoration: const InputDecoration(labelText: 'Целевое время')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _save, child: const Text('Сохранить')),
        ],
      ),
    );
  }
}
