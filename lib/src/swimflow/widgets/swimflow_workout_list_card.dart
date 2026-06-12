import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../logic/workout_wellbeing.dart';
import '../models/swimflow_workout.dart';
import '../theme/coach_theme.dart';
import '../theme/tokens.dart';

class WorkoutListCardTheme {
  const WorkoutListCardTheme({
    required this.cardBackground,
    required this.primary,
    required this.onSurfaceVariant,
    required this.iconBackground,
    required this.strokeBadgeActiveBg,
    required this.strokeBadgeInactiveBg,
    required this.strokeBadgeActiveFg,
    required this.strokeBadgeInactiveFg,
    required this.metricDivider,
    required this.progressTrack,
    required this.titleStyle,
    required this.subtitleStyle,
    required this.capsStyle,
    required this.metricValueStyle,
    required this.strokeBadgeStyle,
  });

  final Color cardBackground;
  final Color primary;
  final Color onSurfaceVariant;
  final Color iconBackground;
  final Color strokeBadgeActiveBg;
  final Color strokeBadgeInactiveBg;
  final Color strokeBadgeActiveFg;
  final Color strokeBadgeInactiveFg;
  final Color metricDivider;
  final Color progressTrack;
  final TextStyle Function(BuildContext) titleStyle;
  final TextStyle Function(BuildContext) subtitleStyle;
  final TextStyle capsStyle;
  final TextStyle metricValueStyle;
  final TextStyle strokeBadgeStyle;

  static WorkoutListCardTheme stitch(BuildContext context) {
    return WorkoutListCardTheme(
      cardBackground: StitchColors.surfaceContainerLowest,
      primary: StitchColors.primary,
      onSurfaceVariant: StitchColors.onSurfaceVariant,
      iconBackground: StitchColors.primaryFixed.withValues(alpha: 0.35),
      strokeBadgeActiveBg: StitchColors.secondaryContainer.withValues(alpha: 0.3),
      strokeBadgeInactiveBg: StitchColors.surfaceContainerHighest,
      strokeBadgeActiveFg: StitchColors.onSecondaryContainer,
      strokeBadgeInactiveFg: StitchColors.onSurfaceVariant,
      metricDivider: StitchColors.primary.withValues(alpha: 0.2),
      progressTrack: StitchColors.surfaceContainerHighest,
      titleStyle: (ctx) => Theme.of(ctx).textTheme.titleMedium!,
      subtitleStyle: (ctx) => Theme.of(ctx).textTheme.bodySmall!,
      capsStyle: GoogleFonts.lexend(fontSize: 11, color: StitchColors.onSurfaceVariant),
      metricValueStyle: GoogleFonts.lexend(fontSize: 22, fontWeight: FontWeight.w600),
      strokeBadgeStyle: GoogleFonts.lexend(fontSize: 10, fontWeight: FontWeight.w700),
    );
  }

  static WorkoutListCardTheme coach(BuildContext context) {
    return WorkoutListCardTheme(
      cardBackground: Colors.white,
      primary: CoachColors.primaryContainer,
      onSurfaceVariant: CoachColors.onSurfaceVariant,
      iconBackground: CoachColors.surfaceContainerLow,
      strokeBadgeActiveBg: CoachColors.secondaryContainer.withValues(alpha: 0.25),
      strokeBadgeInactiveBg: CoachColors.surfaceContainerHighest,
      strokeBadgeActiveFg: CoachColors.secondary,
      strokeBadgeInactiveFg: CoachColors.onSurfaceVariant,
      metricDivider: CoachColors.primary.withValues(alpha: 0.2),
      progressTrack: CoachColors.surfaceContainerLow,
      titleStyle: (ctx) => GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CoachColors.onBackground,
          ),
      subtitleStyle: (ctx) => GoogleFonts.inter(fontSize: 14, color: CoachColors.onSurfaceVariant),
      capsStyle: GoogleFonts.inter(fontSize: 11, color: CoachColors.onSurfaceVariant),
      metricValueStyle: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: CoachColors.onBackground),
      strokeBadgeStyle: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700),
    );
  }
}

String formatWorkoutMetersRu(double m) =>
    '${NumberFormat.decimalPattern('ru').format(m.round())} м';

String workoutDurationLabel(SwimflowWorkout w) {
  final sec = w.durationSeconds;
  if (sec <= 0) return '${w.durationMinutes} мин';
  final m = sec ~/ 60;
  final s = sec % 60;
  if (s == 0) return '$m мин';
  return '$m:${s.toString().padLeft(2, '0')}';
}

double weekTotalMeters(List<SwimflowWorkout> workouts) {
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  var s = 0.0;
  for (final w in workouts) {
    if (w.scheduledAt.isAfter(cutoff)) s += w.distanceMeters;
  }
  return s;
}

class SwimflowWorkoutListWeekSummary extends StatelessWidget {
  const SwimflowWorkoutListWeekSummary({
    required this.weekMeters,
    required this.theme,
    super.key,
  });

  final double weekMeters;
  final WorkoutListCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primary.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ИТОГО ЗА НЕДЕЛЮ', style: theme.capsStyle.copyWith(letterSpacing: 0.6)),
              const SizedBox(height: 4),
              Text(
                formatWorkoutMetersRu(weekMeters),
                style: theme.metricValueStyle.copyWith(color: theme.primary, fontSize: 24),
              ),
            ],
          ),
          Icon(Icons.pool_rounded, color: theme.primary, size: 32),
        ],
      ),
    );
  }
}

class SwimflowWorkoutListCard extends StatelessWidget {
  const SwimflowWorkoutListCard({
    required this.workout,
    required this.theme,
    this.onTap,
    this.coachView = false,
    super.key,
  });

  final SwimflowWorkout workout;
  final WorkoutListCardTheme theme;
  final VoidCallback? onTap;
  final bool coachView;

  bool get _showListSubtitle {
    final s = workout.listSubtitle.trim();
    if (s.isEmpty || s == 'Запись тренера') return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final stroke = workout.strokeLabel.trim();
    final isBreast = stroke == 'БРАСС';
    final showMood = shouldShowWorkoutMoodEmoji(
      scheduledAt: workout.scheduledAt,
      recordMeta: workout.recordMeta,
    );
    return Material(
      color: theme.cardBackground,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.primary.withValues(alpha: 0.08)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.iconBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: showMood
                        ? WorkoutMoodEmoji(
                            recordMeta: workout.recordMeta,
                            scheduledAt: workout.scheduledAt,
                            size: 28,
                          )
                        : Icon(
                            Icons.pool_outlined,
                            size: 22,
                            color: theme.onSurfaceVariant.withValues(alpha: 0.45),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workout.title, style: theme.titleStyle(context)),
                        Text(
                          DateFormat('d MMMM yyyy', 'ru').format(workout.scheduledAt),
                          style: theme.subtitleStyle(context),
                        ),
                        if (_showListSubtitle)
                          Text(
                            workout.listSubtitle,
                            style: theme.subtitleStyle(context).copyWith(
                                  fontSize: 12,
                                  color: theme.onSurfaceVariant.withValues(alpha: 0.85),
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (stroke.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isBreast ? theme.strokeBadgeInactiveBg : theme.strokeBadgeActiveBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        stroke,
                        style: theme.strokeBadgeStyle.copyWith(
                          color: isBreast ? theme.strokeBadgeInactiveFg : theme.strokeBadgeActiveFg,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCol(
                      cap: 'Дистанция',
                      val: '${workout.distanceMeters.round()} м',
                      theme: theme,
                    ),
                  ),
                  Expanded(
                    child: _MetricCol(
                      cap: 'Время',
                      val: workoutDurationLabel(workout),
                      theme: theme,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCol extends StatelessWidget {
  const _MetricCol({required this.cap, required this.val, required this.theme});

  final String cap;
  final String val;
  final WorkoutListCardTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: theme.metricDivider, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(cap.toUpperCase(), style: theme.capsStyle),
          Text(val, style: theme.metricValueStyle),
        ],
      ),
    );
  }
}
