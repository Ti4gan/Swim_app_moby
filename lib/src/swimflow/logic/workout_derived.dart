String workoutPacePer100({required double distanceMeters, required int durationSeconds}) {
  if (distanceMeters <= 0 || durationSeconds <= 0) return '—';
  final secPer100 = (durationSeconds / distanceMeters) * 100;
  final m = secPer100 ~/ 60;
  final s = (secPer100 % 60).round();
  final ss = s < 10 ? '0$s' : '$s';
  return '$m:$ss';
}

int workoutLaps(double distanceMeters, {double poolLengthMeters = 50}) {
  if (distanceMeters <= 0 || poolLengthMeters <= 0) return 0;
  return (distanceMeters / poolLengthMeters).round();
}

String workoutListSubtitle({
  required String stored,
  required DateTime scheduledAt,
  required double distanceMeters,
  Map<String, dynamic>? recordMeta,
}) {
  final trimmed = stored.trim();
  if (trimmed == 'Запись тренера' || trimmed == 'Только что') return trimmed;
  if (recordMeta?['enteredByCoach'] == true) return 'Запись тренера';
  final today = DateTime.now();
  final day = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day);
  final todayDay = DateTime(today.year, today.month, today.day);
  if (day.isAfter(todayDay)) return 'Запланировано';
  if (distanceMeters > 0) return '${distanceMeters.round()} м';
  if (trimmed.isNotEmpty) return trimmed;
  return '—';
}

String workoutStrokeLabelFromMeta({
  required String stored,
  Map<String, dynamic>? recordMeta,
  String fallback = 'КОМПЛЕКС',
}) {
  final sets = recordMeta?['sets'];
  if (sets is! List || sets.isEmpty) {
    return stored.trim().isEmpty ? fallback : stored;
  }
  final keys = <String>{};
  for (final raw in sets) {
    if (raw is! Map) continue;
    final sk = raw['strokeKey'];
    if (sk is String && sk.isNotEmpty) keys.add(sk);
  }
  if (keys.length >= 2) return 'КОМПЛЕКС';
  if (keys.length == 1) {
    switch (keys.first) {
      case 'breast':
        return 'БРАСС';
      case 'back':
        return 'СПИНА';
      case 'fly':
        return 'БАТТЕРФЛЯЙ';
      case 'im':
        return 'КОМПЛЕКС';
      default:
        return 'КРОЛЬ';
    }
  }
  return stored.trim().isEmpty ? fallback : stored;
}

String? workoutAthleteUidFromDocPath(String? path) {
  if (path == null) return null;
  final parts = path.split('/');
  final i = parts.indexOf('users');
  if (i < 0 || i + 1 >= parts.length) return null;
  return parts[i + 1];
}
