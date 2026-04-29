import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/models/user_role.dart';
import '../../providers/auth_providers.dart';
import '../../providers/demo_seed_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).valueOrNull;
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Сводка'),
            actions: [
              IconButton(
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.account_circle_outlined, size: 30),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildActivityCard(context),
                const SizedBox(height: 16),
                _buildSectionTitle(context, 'Ваши показатели'),
                const SizedBox(height: 8),
                _buildMetricsGrid(context),
                const SizedBox(height: 24),
                if (user?.role == UserRole.coach) ...[
                  _buildSectionTitle(context, 'Инструменты тренера'),
                  const SizedBox(height: 8),
                  _buildCoachTools(context, ref),
                ],
                if (user?.role == UserRole.admin) ...[
                  _buildSectionTitle(context, 'Администрирование'),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.admin_panel_settings, color: Colors.orange),
                      title: const Text('Заявки тренеров'),
                      subtitle: const Text('Подтверждение и отклонение'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/admin/coach-approval'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Последние отчеты'),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.assessment_outlined, color: Colors.purple),
                    title: const Text('Эффективность'),
                    subtitle: const Text('План/факт за неделю: 82%'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/reports'),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Активность сегодня',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '12 Окт',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActivityRing(450, 600, Colors.red, Icons.directions_run),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      _buildActivityRow('Тренировка', '1 / 1', Colors.blue),
                      const Divider(),
                      _buildActivityRow('Дистанция', '2500м / 3000м', Colors.cyan),
                      const Divider(),
                      _buildActivityRow('Время', '45 мин / 60 мин', Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRing(double value, double total, Color color, IconData icon) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: value / total,
            strokeWidth: 8,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
        ),
        Icon(icon, color: color),
      ],
    );
  }

  Widget _buildActivityRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(context, 'Пульс', '68 уд/м', Icons.favorite, Colors.red),
        _buildMetricCard(context, 'Сон', '7ч 20м', Icons.bedtime, Colors.indigo),
        _buildMetricCard(context, 'Вес', '74.5 кг', Icons.monitor_weight, Colors.orange),
        _buildMetricCard(context, 'SWOLF', '32', Icons.speed, Colors.teal),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 4),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachTools(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.people_outline, color: Colors.blue),
            title: const Text('Мои спортсмены'),
            subtitle: const Text('Список и управление'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/coach/athletes'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.add_task, color: Colors.green),
            title: const Text('Создать план'),
            subtitle: const Text('Новая тренировка'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/coach/create-plan'),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.science_outlined, color: Colors.purple),
            title: const Text('Генерация демо-данных'),
            subtitle: const Text('Для презентации'),
            onTap: () async {
              final code = await ref.read(demoSeedControllerProvider).seedCoachDemo(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Демо создано. Код спортсмена: $code')),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
