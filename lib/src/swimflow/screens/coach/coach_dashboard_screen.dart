import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/swimflow_workout.dart';
import '../../providers/data_refresh.dart';
import '../../providers/swimflow_providers.dart';
import '../../widgets/swimflow_refresh.dart';
import '../../theme/coach_theme.dart';
import '../../logic/coach_team_stats.dart';
import '../../widgets/coach_month_summary_bento.dart';
import '../../widgets/coach_team_goals_carousel.dart';
import '../../widgets/coach_widgets.dart';

class CoachDashboardScreen extends ConsumerWidget {
  const CoachDashboardScreen({super.key});

  static List<double> _weekKmBuckets(List<SwimflowWorkout> workouts, DateTime now) {
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final buckets = List<double>.filled(7, 0);
    for (final w in workouts) {
      final m = w.scheduledAt;
      if (m.isBefore(start) || m.isAfter(start.add(const Duration(days: 7)))) continue;
      final idx = m.difference(start).inDays;
      if (idx >= 0 && idx < 7) {
        buckets[idx] += w.distanceMeters / 1000.0;
      }
    }
    return buckets;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(swimflowProfileProvider);
    final athletesAsync = ref.watch(coachAthletesProvider);
    final teamWAsync = ref.watch(coachTeamWorkoutsProvider);
    final now = DateTime.now();
    return Scaffold(
      body: CoachPageBackground(
        child: SwimflowRefreshableScroll(
          color: CoachColors.primaryContainer,
          onRefresh: () => refreshCoachTeamData(ref),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
            const SliverToBoxAdapter(
              child: CoachFlowHeader(),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  profile.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (p) => Text(
                      'Доброе утро, ${p?.displayName.isNotEmpty == true ? p!.displayName.split(' ').first : 'тренер'}',
                      style: GoogleFonts.inter(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: CoachColors.onBackground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () => context.push('/coach/record'),
                          style: FilledButton.styleFrom(
                            backgroundColor: CoachColors.primaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            minimumSize: const Size(0, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Тренировка',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => context.go('/coach/swimmers'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: CoachColors.primary,
                            side: const BorderSide(color: CoachColors.primaryContainer),
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            minimumSize: const Size(0, 52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.groups_outlined, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'Пловцы',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  athletesAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Text('$e'),
                    data: (list) {
                      return teamWAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (e, _) => Text('$e'),
                        data: (tw) {
                          final weekKm = _weekKmBuckets(tw, now);
                          final weekTotalKm = weekKm.fold<double>(0, (a, b) => a + b);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              CoachGlassCard(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          '${list.length}',
                                          style: GoogleFonts.inter(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w800,
                                            color: CoachColors.onBackground,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'в группе',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: CoachColors.secondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              CoachTeamGoalsCarousel(athletes: list),
                              const SizedBox(height: 12),
                              CoachGlassCard(
                                padding: const EdgeInsets.all(18),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${weekTotalKm.toStringAsFixed(1)} км суммарно',
                                      style: GoogleFonts.inter(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: CoachColors.onBackground,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 180,
                                      child: BarChart(
                                        BarChartData(
                                          gridData: const FlGridData(show: false),
                                          borderData: FlBorderData(show: false),
                                          titlesData: FlTitlesData(
                                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (v, _) {
                                                  const names = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
                                                  final i = v.toInt().clamp(0, 6);
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 8),
                                                    child: Text(
                                                      names[i],
                                                      style: GoogleFonts.inter(
                                                        fontSize: 11,
                                                        color: CoachColors.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          barGroups: [
                                            for (var i = 0; i < 7; i++)
                                              BarChartGroupData(
                                                x: i,
                                                barRods: [
                                                  BarChartRodData(
                                                    toY: weekKm[i].clamp(0, 999),
                                                    width: 14,
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                                    color: weekKm[i] > 0
                                                        ? CoachColors.primaryContainer
                                                        : CoachColors.surfaceContainerLow,
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Итоги месяца',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: CoachColors.onBackground,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Builder(
                                builder: (context) {
                                  var goalsAchieved = 0;
                                  var goalsTotal = 0;
                                  for (final a in list) {
                                    final goals = ref.watch(athletePerformanceGoalsFamily(a.uid)).valueOrNull ?? [];
                                    final swims = ref.watch(athleteCompetitionSwimsFamily(a.uid)).valueOrNull ?? [];
                                    final t = coachTeamGoalsTotals(goals: goals, swims: swims);
                                    goalsAchieved += t.achieved;
                                    goalsTotal += t.total;
                                  }
                                  return CoachTeamMonthSummaryBento(
                                    goalsAchieved: goalsAchieved,
                                    goalsTotal: goalsTotal,
                                    averageMoodLabel: coachAverageMoodLabelRu(tw, now),
                                    averageMoodEmoji: coachAverageMoodEmoji(tw, now),
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
