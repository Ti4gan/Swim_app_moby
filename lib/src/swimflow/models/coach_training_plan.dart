abstract final class CoachPlanStroke {
  static const free = 'free';
  static const breast = 'breast';
  static const fly = 'fly';
  static const back = 'back';

  static const List<String> ids = [free, breast, fly, back];

  static String labelRu(String id) {
    switch (id) {
      case breast:
        return 'Брасс';
      case fly:
        return 'Баттерфляй';
      case back:
        return 'На спине';
      case free:
      default:
        return 'Вольный';
    }
  }
}

class CoachPlanInterval {
  const CoachPlanInterval({
    required this.blockTitle,
    required this.repetitions,
    required this.intervalMeters,
    required this.stroke,
    required this.intensityTier,
    this.notes = '',
  });

  final String blockTitle;
  final int repetitions;
  final int intervalMeters;
  final String stroke;
  final int intensityTier;
  final String notes;

  int get volumeMeters {
    final r = repetitions <= 0 ? 0 : repetitions;
    final m = intervalMeters <= 0 ? 0 : intervalMeters;
    return r * m;
  }

  Map<String, dynamic> toMap() => {
        'blockTitle': blockTitle,
        'repetitions': repetitions,
        'intervalMeters': intervalMeters,
        'stroke': stroke,
        'intensityTier': intensityTier.clamp(0, 3),
        'notes': notes,
      };

  factory CoachPlanInterval.fromMap(Map<String, dynamic> m) {
    final reps = (m['repetitions'] as num?)?.toInt();
    if (reps != null) {
      return CoachPlanInterval(
        blockTitle: m['blockTitle'] as String? ?? '',
        repetitions: reps <= 0 ? 1 : reps,
        intervalMeters: (m['intervalMeters'] as num?)?.toInt() ?? 0,
        stroke: m['stroke'] as String? ?? CoachPlanStroke.free,
        intensityTier: (m['intensityTier'] as num?)?.toInt() ?? 1,
        notes: m['notes'] as String? ?? '',
      );
    }
    final legacyTitle = m['title'] as String? ?? '';
    final legacyM = (m['suggestedMeters'] as num?)?.toInt() ?? 0;
    return CoachPlanInterval(
      blockTitle: legacyTitle,
      repetitions: 1,
      intervalMeters: legacyM,
      stroke: CoachPlanStroke.free,
      intensityTier: 1,
      notes: m['notes'] as String? ?? '',
    );
  }

  CoachPlanInterval copyWith({
    String? blockTitle,
    int? repetitions,
    int? intervalMeters,
    String? stroke,
    int? intensityTier,
    String? notes,
  }) {
    return CoachPlanInterval(
      blockTitle: blockTitle ?? this.blockTitle,
      repetitions: repetitions ?? this.repetitions,
      intervalMeters: intervalMeters ?? this.intervalMeters,
      stroke: stroke ?? this.stroke,
      intensityTier: intensityTier ?? this.intensityTier,
      notes: notes ?? this.notes,
    );
  }
}
