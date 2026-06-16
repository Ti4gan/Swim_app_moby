import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/data_refresh.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import '../widgets/stitch_app_header.dart';
import '../widgets/stitch_widgets.dart';
import '../widgets/swimflow_refresh.dart';
import '../widgets/swimflow_workout_list_card.dart';

class _WorkoutFilter {
  const _WorkoutFilter({this.period});
  final String? period;

  _WorkoutFilter copyWith({String? period}) {
    return _WorkoutFilter(period: period ?? this.period);
  }

  bool matches(DateTime d) {
    if (period == null) return true;
    final now = DateTime.now();
    if (period == 'day') {
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }
    if (period == 'week') {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      return d.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          d.isBefore(endOfWeek.add(const Duration(days: 1)));
    }
    if (period == 'month') {
      return d.year == now.year && d.month == now.month;
    }
    return true;
  }
}

class StitchTrainingsScreen extends ConsumerStatefulWidget {
  const StitchTrainingsScreen({super.key});

  @override
  ConsumerState<StitchTrainingsScreen> createState() => _StitchTrainingsScreenState();
}

class _StitchTrainingsScreenState extends ConsumerState<StitchTrainingsScreen> {
  _WorkoutFilter _filter = const _WorkoutFilter();

  String _filterLabel() {
    switch (_filter.period) {
      case 'day':
        return 'День';
      case 'week':
        return 'Неделя';
      case 'month':
        return 'Месяц';
      default:
        return 'Все';
    }
  }

  void _onPeriod(String? value) {
    setState(() => _filter = _filter.copyWith(period: value));
  }

  @override
  Widget build(BuildContext context) {
    final workouts = ref.watch(swimflowWorkoutsProvider);
    final list = workouts.valueOrNull ?? [];
    final filtered = list.where((w) => _filter.matches(w.scheduledAt)).toList();
    final weekM = weekTotalMeters(filtered);
    final cardTheme = WorkoutListCardTheme.stitch(context);

    return Scaffold(
      body: StitchPageScaffold(
        bottomInset: 96,
        child: Column(
          children: [
            const StitchMainShellHeader(),
            Expanded(
              child: SwimflowRefreshableScroll(
                onRefresh: () => refreshSwimmerWorkouts(ref),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Мои тренировки', style: Theme.of(context).textTheme.headlineSmall),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.filter_list_rounded),
                          tooltip: 'Фильтр',
                          initialValue: _filter.period,
                          onSelected: _onPeriod,
                          itemBuilder: (context) {
                            return const [
                              PopupMenuItem(value: 'day', child: Text('День')),
                              PopupMenuItem(value: 'week', child: Text('Неделя')),
                              PopupMenuItem(value: 'month', child: Text('Месяц')),
                              PopupMenuItem(value: '', child: Text('Все')),
                            ];
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SwimflowWorkoutListWeekSummary(weekMeters: weekM, theme: cardTheme),
                    const SizedBox(height: 24),
                    workouts.when(
                      data: (list) {
                        final items = filtered;
                        if (items.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              list.isEmpty
                                  ? 'Тренировки появятся после записи тренером.'
                                  : 'Нет тренировок по выбранному фильтру.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: StitchColors.onSurfaceVariant,
                                  ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            for (final w in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: SwimflowWorkoutListCard(
                                  workout: w,
                                  theme: cardTheme,
                                  onTap: () => context.push('/workout/${w.id}'),
                                ),
                              ),
                          ],
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (e, _) => Text('$e'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
