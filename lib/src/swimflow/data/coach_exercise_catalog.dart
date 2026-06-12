import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/coach_template_type.dart';
import '../models/coach_training_plan.dart';

class CoachCatalogExercise {
  const CoachCatalogExercise({
    required this.id,
    required this.title,
    required this.hint,
    required this.presetReps,
    required this.presetIntervalMeters,
    this.defaultIntensityTier = 1,
    this.templateType = CoachTemplateType.aerobic,
    this.strokeKey = 'free',
    this.sortOrder = 0,
    this.isCustom = false,
  });

  final String id;
  final String title;
  final String hint;
  final int presetReps;
  final int presetIntervalMeters;
  final int defaultIntensityTier;
  final String templateType;
  final String strokeKey;
  final int sortOrder;
  final bool isCustom;

  int get volumeMeters {
    final r = presetReps <= 0 ? 1 : presetReps;
    final m = presetIntervalMeters <= 0 ? 0 : presetIntervalMeters;
    return r * m;
  }

  String get intervalLabel {
    final r = presetReps <= 0 ? 1 : presetReps;
    final m = presetIntervalMeters <= 0 ? 0 : presetIntervalMeters;
    return r > 1 ? '$r×$m м' : '$m м';
  }

  CoachPlanInterval toInterval() {
    return CoachPlanInterval(
      blockTitle: title,
      repetitions: presetReps <= 0 ? 1 : presetReps,
      intervalMeters: presetIntervalMeters <= 0 ? 0 : presetIntervalMeters,
      stroke: strokeKey,
      intensityTier: defaultIntensityTier.clamp(0, 3),
      notes: hint,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'hint': hint,
        'presetReps': presetReps,
        'presetIntervalMeters': presetIntervalMeters,
        'defaultIntensityTier': defaultIntensityTier,
        'templateType': templateType,
        'strokeKey': strokeKey,
        'sortOrder': sortOrder,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  factory CoachCatalogExercise.fromFirestore(String id, Map<String, dynamic> m, {bool isCustom = false}) {
    final reps = (m['presetReps'] as num?)?.toInt() ?? 1;
    final interval = (m['presetIntervalMeters'] as num?)?.toInt() ?? 0;
    final legacyMeters = (m['recommendedMeters'] as num?)?.toInt() ?? 0;
    final resolvedInterval = interval > 0 ? interval : (reps > 0 && legacyMeters > 0 ? legacyMeters ~/ reps : 0);
    return CoachCatalogExercise(
      id: id,
      title: m['title'] as String? ?? '',
      hint: m['hint'] as String? ?? '',
      presetReps: reps <= 0 ? 1 : reps,
      presetIntervalMeters: resolvedInterval,
      defaultIntensityTier: (m['defaultIntensityTier'] as num?)?.toInt() ?? 1,
      templateType: m['templateType'] as String? ?? CoachTemplateType.aerobic,
      strokeKey: m['strokeKey'] as String? ?? 'free',
      sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
      isCustom: isCustom,
    );
  }
}

const List<CoachCatalogExercise> kCoachExerciseCatalog = [
  CoachCatalogExercise(
    id: 'warm400',
    sortOrder: 0,
    title: 'Разминка вольным стилем',
    hint: 'Постепенное ускорение каждые 100 м',
    presetReps: 1,
    presetIntervalMeters: 400,
    defaultIntensityTier: 0,
    templateType: CoachTemplateType.warmup,
    strokeKey: 'free',
  ),
  CoachCatalogExercise(
    id: 'kick8x50',
    sortOrder: 1,
    title: 'Ноги с доской',
    hint: 'Отдых 15 с',
    presetReps: 8,
    presetIntervalMeters: 50,
    defaultIntensityTier: 1,
    templateType: CoachTemplateType.technique,
    strokeKey: 'free',
  ),
  CoachCatalogExercise(
    id: 'pull6x100',
    sortOrder: 2,
    title: 'Руки с лопатками',
    hint: 'Отдых 20 с',
    presetReps: 6,
    presetIntervalMeters: 100,
    defaultIntensityTier: 1,
    templateType: CoachTemplateType.technique,
    strokeKey: 'free',
  ),
  CoachCatalogExercise(
    id: 'aerobic10x200',
    sortOrder: 3,
    title: 'Аэробная серия кроль',
    hint: 'RPE 6–7, отдых 25–30 с',
    presetReps: 10,
    presetIntervalMeters: 200,
    defaultIntensityTier: 1,
    templateType: CoachTemplateType.aerobic,
    strokeKey: 'free',
  ),
  CoachCatalogExercise(
    id: 'threshold8x150',
    sortOrder: 4,
    title: 'Порог 8×150 м',
    hint: 'Отдых 20 с',
    presetReps: 8,
    presetIntervalMeters: 150,
    defaultIntensityTier: 2,
    templateType: CoachTemplateType.threshold,
    strokeKey: 'free',
  ),
  CoachCatalogExercise(
    id: 'sprint12x25',
    sortOrder: 5,
    title: 'Спринт 12×25 м',
    hint: 'Отдых 30–45 с',
    presetReps: 12,
    presetIntervalMeters: 25,
    defaultIntensityTier: 3,
    templateType: CoachTemplateType.sprint,
    strokeKey: 'free',
  ),
  CoachCatalogExercise(
    id: 'im400',
    sortOrder: 6,
    title: 'Комплекс IM 4×100 м',
    hint: 'По одному отрезку на стиль',
    presetReps: 4,
    presetIntervalMeters: 100,
    defaultIntensityTier: 2,
    templateType: CoachTemplateType.im,
    strokeKey: 'im',
  ),
  CoachCatalogExercise(
    id: 'cool300',
    sortOrder: 7,
    title: 'Заминка вольным',
    hint: 'Метры расслабленно',
    presetReps: 1,
    presetIntervalMeters: 300,
    defaultIntensityTier: 0,
    templateType: CoachTemplateType.cooldown,
    strokeKey: 'free',
  ),
];
