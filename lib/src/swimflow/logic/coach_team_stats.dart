import '../models/competition_swim.dart';
import '../models/performance_goal.dart';
import '../models/swimflow_workout.dart';
import 'performance_goal_logic.dart';
import 'workout_wellbeing.dart';

class CoachTeamGoalsTotals {
  const CoachTeamGoalsTotals({required this.achieved, required this.total});

  final int achieved;
  final int total;
}

CoachTeamGoalsTotals coachTeamGoalsTotals({
  required List<PerformanceGoal> goals,
  required List<CompetitionSwim> swims,
}) {
  var achieved = 0;
  for (final g in goals) {
    final progress = buildPerformanceGoalProgress(goal: g, swims: swims);
    if (progress.achieved) achieved++;
  }
  return CoachTeamGoalsTotals(achieved: achieved, total: goals.length);
}

bool coachWorkoutHasMood(Map<String, dynamic>? meta) {
  if (meta == null) return false;
  final mood = '${meta['mood'] ?? ''}'.trim();
  if (mood.isEmpty || mood == '—') return false;
  final idx = int.tryParse(mood);
  return idx != null && idx >= 0 && idx <= 4;
}

bool coachWorkoutInRollingMonthFromDay(DateTime scheduledAt, DateTime throughDay) {
  final end = DateTime(throughDay.year, throughDay.month, throughDay.day);
  final start = end.subtract(const Duration(days: 29));
  final day = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
  return !day.isBefore(start) && !day.isAfter(end);
}

List<int> _coachMoodIndicesRollingMonth(List<SwimflowWorkout> workouts, DateTime throughDay) {
  final indices = <int>[];
  for (final w in workouts) {
    if (!coachWorkoutInRollingMonthFromDay(w.scheduledAt, throughDay)) continue;
    if (isWorkoutScheduledInFuture(w.scheduledAt)) continue;
    if (!coachWorkoutHasMood(w.recordMeta)) continue;
    indices.add(parseWorkoutMoodIndex(w.recordMeta));
  }
  return indices;
}

String? coachAverageMoodLabelRu(List<SwimflowWorkout> workouts, DateTime throughDay) {
  final indices = _coachMoodIndicesRollingMonth(workouts, throughDay);
  if (indices.isEmpty) return null;
  final avg = indices.reduce((a, b) => a + b) / indices.length;
  final idx = avg.round().clamp(0, workoutMoodLabelsRu.length - 1);
  return workoutMoodLabelsRu[idx];
}

String? coachAverageMoodEmoji(List<SwimflowWorkout> workouts, DateTime throughDay) {
  final indices = _coachMoodIndicesRollingMonth(workouts, throughDay);
  if (indices.isEmpty) return null;
  final avg = indices.reduce((a, b) => a + b) / indices.length;
  final idx = avg.round().clamp(0, workoutMoodEmojis.length - 1);
  return workoutMoodEmojis[idx];
}
