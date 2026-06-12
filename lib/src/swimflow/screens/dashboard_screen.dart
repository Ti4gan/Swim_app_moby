import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/auth_providers.dart';
import '../logic/performance_goal_logic.dart';
import '../logic/workout_calories.dart';
import '../models/swimflow_workout.dart';
import '../providers/data_refresh.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import '../widgets/performance_goal_chart.dart';
import '../widgets/stitch_app_header.dart';
import '../widgets/stitch_widgets.dart';
import '../widgets/swimflow_refresh.dart';
import '../widgets/swimmer_goals_carousel.dart';

class StitchDashboardScreen extends ConsumerStatefulWidget {
  const StitchDashboardScreen({super.key});

  @override
  ConsumerState<StitchDashboardScreen> createState() => _StitchDashboardScreenState();
}

class _StitchDashboardScreenState extends ConsumerState<StitchDashboardScreen> {
  final _goalPageController = PageController();
  int _goalPage = 0;

  @override
  void dispose() {
    _goalPageController.dispose();
    super.dispose();
  }

  String _firstName(String full) {
    final p = full.trim().split(' ');
    return p.isNotEmpty ? p.first : full;
  }

  void _clampGoalPage(int goalCount) {
    if (goalCount == 0) {
      if (_goalPage != 0) setState(() => _goalPage = 0);
      return;
    }
    if (_goalPage >= goalCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _goalPage = goalCount - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(swimflowProfileProvider);
    final workouts = ref.watch(swimflowWorkoutsProvider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final goalsAsync = uid == null ? null : ref.watch(athletePerformanceGoalsFamily(uid));
    final swimsAsync = ref.watch(swimflowCompetitionSwimsProvider);

    return Scaffold(
      body: StitchPageScaffold(
        child: Column(
          children: [
            const StitchMainShellHeader(),
            Expanded(
              child: SwimflowRefreshableScroll(
                color: StitchColors.primary,
                onRefresh: () => refreshSwimmerDashboard(ref),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  children: [
                    profile.when(
                      data: (p) {
                        if (p == null) return const SizedBox(height: 80);
                        final name = p.displayName.trim().isEmpty ? 'пловец' : _firstName(p.displayName);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Доброе утро, $name!',
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Вода сегодня идеальной температуры. Готовы к заплыву?',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: StitchColors.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(height: 80),
                      error: (_, __) => const SizedBox(height: 80),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Тренировка', style: Theme.of(context).textTheme.headlineSmall),
                        TextButton(
                          onPressed: () {
                            final list = ref.read(swimflowWorkoutsProvider).valueOrNull;
                            if (list != null && list.isNotEmpty) {
                              context.push('/workout/${list.first.id}');
                            }
                          },
                          child: const Text('Открыть'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    workouts.when(
                      data: (list) => _LastSwimCard(workout: list.isEmpty ? null : list.first),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 28),
                    if (goalsAsync != null && swimsAsync.hasValue) ...[
                      goalsAsync.when(
                        data: (goals) {
                          _clampGoalPage(goals.length);
                          final swims = swimsAsync.value ?? [];
                          if (goals.isEmpty) {
                            return StitchSurfaceCard(
                              child: Text(
                                'Тренер ещё не задал цели по результату.',
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: StitchColors.onSurfaceVariant,
                                    ),
                              ),
                            );
                          }
                          final idx = _goalPage.clamp(0, goals.length - 1);
                          final selected = goals[idx];
                          final progress = buildPerformanceGoalProgress(goal: selected, swims: swims);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SwimmerGoalsCarousel(
                                goals: goals,
                                swims: swims,
                                pageController: _goalPageController,
                                onPageChanged: (i) => setState(() => _goalPage = i),
                              ),
                              const SizedBox(height: 28),
                              Text('Прогресс', style: Theme.of(context).textTheme.headlineSmall),
                              const SizedBox(height: 12),
                              StitchSurfaceCard(
                                padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Динамика результата',
                                      style: GoogleFonts.lexend(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      progress.points.isEmpty
                                          ? 'Пока нет точек на графике'
                                          : '${progress.points.length} стартов',
                                      style: TextStyle(
                                        color: StitchColors.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    PerformanceGoalChart(
                                      progress: progress,
                                      primary: StitchColors.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('$e'),
                      ),
                    ] else if (goalsAsync != null) ...[
                      goalsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => Text('$e'),
                        data: (_) => const SizedBox.shrink(),
                      ),
                    ],
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

class _LastSwimCard extends StatelessWidget {
  const _LastSwimCard({required this.workout});

  final SwimflowWorkout? workout;

  @override
  Widget build(BuildContext context) {
    if (workout == null) {
      return StitchSurfaceCard(
        child: Text(
          'Пока нет тренировок',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: StitchColors.onSurfaceVariant,
              ),
        ),
      );
    }
    final w = workout!;
    return StitchSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: StitchColors.primaryFixed.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.waves_rounded, color: StitchColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(w.title, style: Theme.of(context).textTheme.titleMedium),
                    Text(w.listSubtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Text(
                '${w.distanceMeters.toStringAsFixed(0)} м',
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: StitchColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StitchColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ВРЕМЯ',
                        style: GoogleFonts.lexend(fontSize: 10, color: StitchColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 18, color: StitchColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${w.durationMinutes} мин',
                            style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StitchColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'КАЛОРИИ',
                        style: GoogleFonts.lexend(fontSize: 10, color: StitchColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              size: 18, color: Colors.orange.shade400),
                          const SizedBox(width: 6),
                          Text(
                            '${w.displayKcal} ккал',
                            style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
