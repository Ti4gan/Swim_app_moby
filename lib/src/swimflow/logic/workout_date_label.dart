import 'package:intl/intl.dart';

String workoutDetailDateLabelRu(DateTime scheduledAt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'Сегодня';
  if (diff == -1) return 'Вчера';
  return DateFormat('d MMMM', 'ru').format(scheduledAt);
}

DateTime combineWorkoutScheduleDate(DateTime date, {DateTime? timeSource}) {
  final t = timeSource ?? DateTime.now();
  return DateTime(date.year, date.month, date.day, t.hour, t.minute, t.second);
}
