import 'dart:math' as math;

import '../models/swimflow_workout.dart';

abstract final class WorkoutCalories {
  static int displayFor(SwimflowWorkout w) {
    final meta = w.recordMeta;
    final sets = _parseSets(meta?['sets']);
    return estimateFromRecording(
      totalMeters: w.distanceMeters,
      durationSeconds: w.durationSeconds,
      mood: meta?['mood'],
      fatigue01to10: _parseFatigue(meta?['fatigue']),
      physicalState: '${meta?['physicalState'] ?? 'normal'}',
      sets: sets,
      strokeLabelFallback: w.strokeLabel,
    );
  }

  static int estimateFromRecording({
    required double totalMeters,
    required int durationSeconds,
    required dynamic mood,
    required int fatigue01to10,
    required String physicalState,
    required List<Map<String, dynamic>> sets,
    String strokeLabelFallback = 'КОМПЛЕКС',
  }) {
    if (totalMeters <= 0) return 0;
    final mood01 = _moodScore01(mood);
    final fat = fatigue01to10.clamp(1, 10);
    final phys = _physicalMul(physicalState);
    final secRaw = durationSeconds.clamp(0, 86400);
    final km = totalMeters / 1000.0;
    final hours = secRaw > 0 ? secRaw / 3600.0 : math.max(km / 2.2, 1 / 120);
    final paceKmH = km / hours;

    double strokeWeighted = 0;
    double intWeighted = 0;
    double metersAcc = 0;
    for (final s in sets) {
      final m = (s['meters'] as num?)?.toDouble() ?? 0;
      if (m <= 0) continue;
      final sk = _strokeKeyFromSet(s) ?? _strokeKeyFromLabel(strokeLabelFallback);
      final idx = (s['intensityIndex'] as num?)?.toInt() ?? 1;
      strokeWeighted += m * _strokeMul(sk);
      intWeighted += m * _intensityMul(idx);
      metersAcc += m;
    }
    if (metersAcc <= 0) {
      final sk = _strokeKeyFromLabel(strokeLabelFallback);
      strokeWeighted = totalMeters * _strokeMul(sk);
      intWeighted = totalMeters * _intensityMul(1);
      metersAcc = totalMeters;
    }
    final avgStroke = strokeWeighted / metersAcc;
    final avgInt = intWeighted / metersAcc;

    var kcal = km * 198.0 * avgStroke * avgInt;
    if (paceKmH > 2.6) {
      kcal *= 1.06;
    } else if (paceKmH < 1.15) {
      kcal *= 0.94;
    }
    kcal *= 1.0 + (fat - 5) * 0.014;
    kcal *= phys;
    kcal *= 1.0 + (mood01 - 0.5) * 0.04;
    return kcal.round().clamp(18, 6000);
  }

  static List<Map<String, dynamic>> _parseSets(dynamic raw) {
    if (raw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(e);
      } else if (e is Map) {
        out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
  }

  static int _parseFatigue(dynamic v) {
    if (v is num) return v.round().clamp(1, 10);
    if (v is String) {
      final n = int.tryParse(v);
      if (n != null) return n.clamp(1, 10);
    }
    return 5;
  }

  static double _moodScore01(dynamic mood) {
    if (mood is num) return (mood.toDouble() / 4.0).clamp(0.0, 1.0);
    if (mood is String) {
      final n = int.tryParse(mood);
      if (n != null) return (n / 4.0).clamp(0.0, 1.0);
      final t = mood.trim().toLowerCase();
      if (t.contains('отлично') || t.contains('супер')) return 1.0;
      if (t.contains('хорошо') || t.contains('радост')) return 0.75;
      if (t.contains('устал') || t.contains('норм')) return 0.45;
      if (t.contains('плохо') || t.contains('груст')) return 0.15;
    }
    return 0.5;
  }

  static double _physicalMul(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'energy' || s.contains('энергич')) return 1.045;
    if (s == 'tired' || s.contains('устав')) return 0.965;
    return 1.0;
  }

  static double _intensityMul(int index) {
    final i = index.clamp(0, 3);
    return 0.88 + 0.19 * i;
  }

  static double _strokeMul(String key) {
    switch (key) {
      case 'fly':
        return 1.12;
      case 'breast':
        return 1.085;
      case 'back':
        return 1.025;
      case 'im':
        return 1.055;
      default:
        return 1.0;
    }
  }

  static String? _strokeKeyFromSet(Map<String, dynamic> s) {
    final k = s['strokeKey'];
    if (k is String && k.isNotEmpty) return k;
    final sub = s['subtitle'];
    if (sub is String) return _strokeKeyFromSubtitle(sub);
    return null;
  }

  static String? _strokeKeyFromSubtitle(String sub) {
    final t = sub.toLowerCase();
    if (t.contains('баттерф') || t.contains('fly')) return 'fly';
    if (t.contains('брасс')) return 'breast';
    if (t.contains('спин') || t.contains('на спине')) return 'back';
    if (t.contains('комплекс')) return 'im';
    if (t.contains('вольн') || t.contains('крол')) return 'free';
    return null;
  }

  static String _strokeKeyFromLabel(String label) {
    final u = label.toUpperCase();
    if (u.contains('БРАСС')) return 'breast';
    if (u.contains('СПИН')) return 'back';
    if (u.contains('БАТТЕР') || u.contains('FLY')) return 'fly';
    if (u.contains('КОМПЛЕКС') || u.contains('IM')) return 'im';
    if (u.contains('КРОЛЬ') || u.contains('ВОЛЬН')) return 'free';
    return 'free';
  }
}

extension SwimflowWorkoutKcalX on SwimflowWorkout {
  int get displayKcal => WorkoutCalories.displayFor(this);
}
