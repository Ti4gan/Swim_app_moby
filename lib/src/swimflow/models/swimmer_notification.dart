import 'swimflow_workout.dart';

class SwimmerNotification {
  const SwimmerNotification({
    required this.workoutId,
    required this.title,
    required this.distanceMeters,
    required this.scheduledAt,
  });

  final String workoutId;
  final String title;
  final double distanceMeters;
  final DateTime scheduledAt;

  factory SwimmerNotification.fromWorkout(SwimflowWorkout w) {
    return SwimmerNotification(
      workoutId: w.id,
      title: w.title.trim().isEmpty ? 'Тренировка' : w.title.trim(),
      distanceMeters: w.distanceMeters,
      scheduledAt: w.scheduledAt,
    );
  }
}

bool isCoachRecordedWorkout(SwimflowWorkout w) {
  final coachId = w.coachId;
  if (coachId == null || coachId.isEmpty) return false;
  final meta = w.recordMeta;
  if (meta != null && meta['enteredByCoach'] == true) return true;
  return w.listSubtitle.contains('Запись тренера');
}
