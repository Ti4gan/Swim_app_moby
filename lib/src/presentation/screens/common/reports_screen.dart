import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/report_period.dart';
import '../../../domain/models/user_role.dart';
import '../../providers/admin_coach_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/report_providers.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authSessionProvider).valueOrNull;
    final report = ref.watch(performanceReportProvider);
    final period = ref.watch(reportPeriodProvider);
    final coachRows = ref.watch(coachAthleteReportsProvider);
    final athletes = ref.watch(coachAthletesProvider).valueOrNull ?? const [];
    final selectedAthleteId = ref.watch(selectedAthleteIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Отчеты')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<ReportPeriod>(
            segments: const [
              ButtonSegment(value: ReportPeriod.day, label: Text('День')),
              ButtonSegment(value: ReportPeriod.week, label: Text('Неделя')),
              ButtonSegment(value: ReportPeriod.month, label: Text('Месяц')),
            ],
            selected: {period},
            onSelectionChanged: (value) {
              ref.read(reportPeriodProvider.notifier).state = value.first;
            },
          ),
          const SizedBox(height: 12),
          if (user?.role == UserRole.coach)
            DropdownButtonFormField<String?>(
              value: selectedAthleteId,
              decoration: const InputDecoration(labelText: 'Фильтр по спортсмену'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Все спортсмены')),
                ...athletes.map(
                  (athlete) => DropdownMenuItem<String?>(
                    value: athlete.id,
                    child: Text(athlete.fullName),
                  ),
                ),
              ],
              onChanged: (value) {
                ref.read(selectedAthleteIdProvider.notifier).state = value;
              },
            ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Эффективность тренировок'),
              subtitle: Text('${report.completionPercent.toStringAsFixed(1)}%'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Сравнение план/факт'),
              subtitle: Text('${report.totalResults} из ${report.totalPlans} выполнено'),
            ),
          ),
          if (user?.role == UserRole.coach) ...[
            const SizedBox(height: 8),
            const Text('Аналитика по спортсменам'),
            const SizedBox(height: 8),
            ...coachRows.map(
              (row) => Card(
                child: ListTile(
                  title: Text(row.athleteName),
                  subtitle: Text(
                    'План: ${row.plannedCount}, Факт: ${row.completedCount}, '
                    'Выполнение: ${row.completionPercent.toStringAsFixed(1)}%, '
                    'План дистанции: ${row.plannedDistanceMeters.toStringAsFixed(0)} м, '
                    'Факт дистанции: ${row.completedDistanceMeters.toStringAsFixed(0)} м',
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final path = await ref.read(reportServiceProvider).exportPerformanceReport(report);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('JSON: $path')));
              }
            },
            child: const Text('Экспорт JSON'),
          ),
          ElevatedButton(
            onPressed: () async {
              final path = await ref.read(reportServiceProvider).exportPerformanceReportCsv(report);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV: $path')));
              }
            },
            child: const Text('Экспорт CSV'),
          ),
          ElevatedButton(
            onPressed: () async {
              final path = await ref.read(reportServiceProvider).exportPerformanceReportPdfStub(report);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF-заготовка: $path')));
              }
            },
            child: const Text('Экспорт PDF (заготовка)'),
          ),
        ],
      ),
    );
  }
}
