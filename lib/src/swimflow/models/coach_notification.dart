import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../logic/workout_wellbeing.dart';
import 'competition_swim.dart';
import 'swimflow_workout.dart';

enum CoachNotificationType { wellbeing, competition }

class CoachNotification {
  const CoachNotification({
    required this.id,
    required this.type,
    required this.athleteUid,
    required this.athleteName,
    required this.title,
    required this.detail,
    required this.subtitle,
    required this.at,
    this.workoutId,
  });

  final String id;
  final CoachNotificationType type;
  final String athleteUid;
  final String athleteName;
  final String title;
  final String detail;
  final String subtitle;
  final DateTime at;
  final String? workoutId;

  factory CoachNotification.fromWellbeingWorkout({
    required SwimflowWorkout workout,
    required String athleteName,
  }) {
    final meta = workout.recordMeta;
    final moodIdx = parseWorkoutMoodIndex(meta);
    final mood = workoutMoodLabelsRu[moodIdx.clamp(0, workoutMoodLabelsRu.length - 1)];
    final at = _wellbeingAt(meta) ?? workout.scheduledAt;
    final workoutTitle = workout.title.trim().isEmpty ? 'Тренировка' : workout.title.trim();
    return CoachNotification(
      id: 'wellbeing:${workout.id}',
      type: CoachNotificationType.wellbeing,
      athleteUid: workout.athleteUid ?? '',
      athleteName: athleteName,
      title: 'Настроение после тренировки',
      detail: athleteName,
      subtitle: '$mood · $workoutTitle · ${DateFormat('d MMMM, HH:mm', 'ru').format(at)}',
      at: at,
      workoutId: workout.id,
    );
  }

  factory CoachNotification.fromCompetitionSwim({
    required String athleteUid,
    required String athleteName,
    required CompetitionSwim swim,
  }) {
    final stroke = competitionStrokeLabelsRu[swim.strokeKey] ?? swim.strokeKey;
    final name = swim.competitionName?.trim();
    final date = swim.eventDate;
    return CoachNotification(
      id: 'competition:${athleteUid}:${swim.id}',
      type: CoachNotificationType.competition,
      athleteUid: athleteUid,
      athleteName: athleteName,
      title: 'Результат соревнования',
      detail: athleteName,
      subtitle:
          '${swim.distanceMeters} м $stroke${name != null && name.isNotEmpty ? ' · $name' : ''} · ${DateFormat('d MMMM, HH:mm', 'ru').format(date)}',
      at: date,
    );
  }

  static DateTime? _wellbeingAt(Map<String, dynamic>? meta) {
    final raw = meta?['wellbeingSavedAt'];
    if (raw is Timestamp) return raw.toDate();
    return null;
  }
}

bool isSwimmerWellbeingNotification(SwimflowWorkout w) {
  final meta = w.recordMeta;
  if (meta == null) return false;
  if (meta['enteredByCoach'] == true) return false;
  return swimmerWellbeingReported(meta);
}
