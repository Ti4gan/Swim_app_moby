class RankNormEntry {
  const RankNormEntry({
    required this.distanceMeters,
    required this.strokeKey,
    required this.timeCentiseconds,
  });

  final int distanceMeters;
  final String strokeKey;
  final int timeCentiseconds;

  factory RankNormEntry.fromMap(Map<String, dynamic> m) {
    const timeKeys = ['menTimeSec', 'womenTimeSec'];
    int timeCs = 0;
    for (final k in timeKeys) {
      final v = m[k];
      if (v is num && v > 0) {
        timeCs = (v * 100).round();
        break;
      }
    }

    return RankNormEntry(
      distanceMeters: _intVal(m, ['distanceMeters', 'distance', 'дистанция']),
      strokeKey: _strVal(m, ['discipline', 'strokeKey', 'stroke', 'style', 'стиль']),
      timeCentiseconds: timeCs,
    );
  }

  static int _intVal(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is num) return v.toInt();
      if (v is String) {
        final cleaned = v.trim().replaceAll(',', '.');
        final parsed = double.tryParse(cleaned);
        if (parsed != null) return (parsed * 100).round();
      }
    }
    return 0;
  }

  static String _strVal(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return '';
  }
}
