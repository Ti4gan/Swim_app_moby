import 'package:flutter/material.dart';

import '../models/swimflow_workout.dart';

const workoutMoodLabelsRu = ['Плохо', 'Так себе', 'Отлично', 'Супер', 'Восторг'];
const workoutMoodEmojis = ['😞', '😐', '🙂', '😄', '🤩'];

bool isWorkoutScheduledInFuture(DateTime scheduledAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
  return day.isAfter(today);
}

bool workoutWellbeingSaved(Map<String, dynamic>? meta) {
  if (meta == null) return false;
  if (meta['wellbeingSaved'] == true) return true;
  if (meta['wellbeingSavedAt'] != null) return true;
  final mood = '${meta['mood'] ?? ''}';
  if (mood == '—' || mood.isEmpty) return false;
  final idx = int.tryParse(mood);
  if (idx == null || idx < 0 || idx > 4) return false;
  final phys = '${meta['physicalState'] ?? ''}';
  if (phys == '—' || phys.isEmpty) return false;
  if (!{'tired', 'normal', 'energy'}.contains(phys)) return false;
  return meta['fatigue'] is num;
}

int parseWorkoutMoodIndex(Map<String, dynamic>? meta, {int fallback = 2}) {
  final moodRaw = meta?['mood'];
  if (moodRaw is num) return moodRaw.toInt().clamp(0, 4);
  return int.tryParse('$moodRaw')?.clamp(0, 4) ?? fallback;
}

int parseWorkoutFatigue(Map<String, dynamic>? meta, {int fallback = 5}) {
  return ((meta?['fatigue'] as num?)?.toInt() ?? fallback).clamp(1, 10);
}

String parseWorkoutPhysicalState(Map<String, dynamic>? meta) {
  final phys = '${meta?['physicalState'] ?? 'normal'}';
  if (phys.contains('tired') || phys.contains('устав')) return 'tired';
  if (phys.contains('energy') || phys.contains('энергич')) return 'energy';
  return 'normal';
}

String physicalStateLabelRu(String value) {
  switch (value) {
    case 'tired':
      return 'Уставший';
    case 'energy':
      return 'Энергичный';
    default:
      return 'Нормально';
  }
}

bool swimmerWellbeingReported(Map<String, dynamic>? meta) {
  if (meta == null) return false;
  if (meta['wellbeingSaved'] == true) return true;
  if (meta['wellbeingSavedAt'] != null) return true;
  if (meta['enteredByCoach'] == true) return false;
  return workoutWellbeingSaved(meta);
}

String? workoutWellbeingListStatusRu({
  required DateTime scheduledAt,
  required Map<String, dynamic>? recordMeta,
  bool forCoach = false,
}) {
  if (isWorkoutScheduledInFuture(scheduledAt)) return null;
  if (forCoach) return null;
  if (swimmerWellbeingReported(recordMeta)) return 'Настроение сохранено';
  return 'Укажите состояние после тренировки';
}

String workoutMoodEmojiChar(Map<String, dynamic>? recordMeta) {
  final idx = parseWorkoutMoodIndex(recordMeta, fallback: 2);
  return workoutMoodEmojis[idx.clamp(0, workoutMoodEmojis.length - 1)];
}

bool shouldShowWorkoutMoodEmoji({
  required DateTime scheduledAt,
  required Map<String, dynamic>? recordMeta,
}) {
  if (isWorkoutScheduledInFuture(scheduledAt)) return false;
  return true;
}

class WorkoutMoodEmoji extends StatelessWidget {
  const WorkoutMoodEmoji({
    required this.recordMeta,
    required this.scheduledAt,
    super.key,
    this.size = 22,
  });

  final Map<String, dynamic>? recordMeta;
  final DateTime scheduledAt;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!shouldShowWorkoutMoodEmoji(scheduledAt: scheduledAt, recordMeta: recordMeta)) {
      return const SizedBox.shrink();
    }
    final reported = swimmerWellbeingReported(recordMeta);
    return Opacity(
      opacity: reported ? 1 : 0.38,
      child: Text(
        workoutMoodEmojiChar(recordMeta),
        style: TextStyle(fontSize: size, height: 1),
      ),
    );
  }
}

SwimflowWorkout? latestPastWorkoutOnDay(List<SwimflowWorkout> workouts, DateTime day) {
  SwimflowWorkout? last;
  for (final w in workouts) {
    if (w.scheduledAt.year != day.year ||
        w.scheduledAt.month != day.month ||
        w.scheduledAt.day != day.day) {
      continue;
    }
    if (isWorkoutScheduledInFuture(w.scheduledAt)) continue;
    if (last == null || w.scheduledAt.isAfter(last.scheduledAt)) {
      last = w;
    }
  }
  return last;
}
