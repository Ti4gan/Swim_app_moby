import '../models/swimflow_workout.dart';

class WorkoutStats {
  const WorkoutStats({
    required this.totalWorkouts,
    required this.totalDistanceMeters,
    required this.workoutsThisMonth,
  });

  static const zero = WorkoutStats(
    totalWorkouts: 0,
    totalDistanceMeters: 0,
    workoutsThisMonth: 0,
  );

  final int totalWorkouts;
  final double totalDistanceMeters;
  final int workoutsThisMonth;
}

WorkoutStats workoutStatsFromList(
  List<SwimflowWorkout> workouts, {
  DateTime? now,
}) {
  final n = now ?? DateTime.now();
  var count = 0;
  var meters = 0.0;
  var monthCount = 0;
  for (final w in workouts) {
    count++;
    meters += w.distanceMeters;
    final at = w.scheduledAt;
    if (at.year == n.year && at.month == n.month) {
      monthCount++;
    }
  }
  return WorkoutStats(
    totalWorkouts: count,
    totalDistanceMeters: meters,
    workoutsThisMonth: monthCount,
  );
}
