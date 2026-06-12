import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../logic/workout_calories.dart';
import '../models/swimflow_intensity.dart';
import '../models/swimflow_workout.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import '../widgets/stitch_app_header.dart';
import '../widgets/stitch_widgets.dart';
import '../widgets/workout_wellbeing_panel.dart';

String _formatWorkoutDurationShort(int sec) {
  if (sec <= 0) return '0 мин';
  final m = sec ~/ 60;
  final s = sec % 60;
  if (m >= 60) {
    final h = m ~/ 60;
    final mm = m % 60;
    return '${h}ч ${mm}м';
  }
  if (s == 0) return '$m мин';
  return '$m:${s.toString().padLeft(2, '0')}';
}

List<_ZoneSlice> _intensitySlices(SwimflowWorkout w) {
  final meta = w.recordMeta;
  if (meta == null) return [];
  final rawSets = meta['sets'];
  if (rawSets is! List || rawSets.isEmpty) return [];
  var total = 0.0;
  final byIdx = [0.0, 0.0, 0.0, 0.0];
  for (final raw in rawSets) {
    if (raw is! Map) continue;
    final m = (raw['meters'] as num?)?.toDouble() ?? 0;
    if (m <= 0) continue;
    total += m;
    var idx = (raw['intensityIndex'] as num?)?.toInt();
    if (idx == null || idx < 0 || idx > 3) idx = 2;
    byIdx[idx] += m;
  }
  if (total <= 0) return [];
  final out = <_ZoneSlice>[];
  for (var i = 3; i >= 0; i--) {
    final share = byIdx[i] / total;
    if (share < 0.001) continue;
    out.add(
      _ZoneSlice(
        label: SwimflowIntensity.labelsRu[i],
        fraction: share,
        color: _intensityColor(i),
        percent: (share * 100).round(),
      ),
    );
  }
  out.sort((a, b) => b.fraction.compareTo(a.fraction));
  return out;
}

Color _intensityColor(int i) {
  switch (i) {
    case 0:
      return StitchColors.primaryFixedDim;
    case 1:
      return StitchColors.primary;
    case 2:
      return Colors.orange.shade400;
    case 3:
      return StitchColors.error;
    default:
      return StitchColors.outline;
  }
}

List<_StrokeSlice> _strokeSlices(SwimflowWorkout w) {
  final meta = w.recordMeta;
  if (meta == null) return [];
  final rawSets = meta['sets'];
  if (rawSets is! List || rawSets.isEmpty) return [];
  final map = <String, double>{};
  var total = 0.0;
  for (final raw in rawSets) {
    if (raw is! Map) continue;
    final m = (raw['meters'] as num?)?.toDouble() ?? 0;
    if (m <= 0) continue;
    final name = (raw['subtitle'] as String?)?.trim().isNotEmpty == true
        ? raw['subtitle'] as String
        : 'Сегмент';
    map[name] = (map[name] ?? 0) + m;
    total += m;
  }
  if (total <= 0) return [];
  final list = map.entries.map((e) {
    final share = e.value / total;
    return _StrokeSlice(name: e.key, fraction: share, percent: (share * 100).round());
  }).toList();
  list.sort((a, b) => b.fraction.compareTo(a.fraction));
  return list;
}

class _ZoneSlice {
  const _ZoneSlice({
    required this.label,
    required this.fraction,
    required this.color,
    required this.percent,
  });

  final String label;
  final double fraction;
  final Color color;
  final int percent;
}

class _StrokeSlice {
  const _StrokeSlice({
    required this.name,
    required this.fraction,
    required this.percent,
  });

  final String name;
  final double fraction;
  final int percent;
}

class _WorkoutSetItem {
  const _WorkoutSetItem({
    required this.title,
    required this.subtitle,
    required this.meters,
    required this.intensityIndex,
    required this.intensityLabel,
  });

  final String title;
  final String subtitle;
  final int meters;
  final int intensityIndex;
  final String intensityLabel;
}

List<_WorkoutSetItem> _workoutSets(SwimflowWorkout w) {
  final meta = w.recordMeta;
  if (meta == null) return [];
  final raw = meta['sets'];
  if (raw is! List) return [];
  final out = <_WorkoutSetItem>[];
  for (final rawItem in raw) {
    if (rawItem is! Map) continue;
    final meters = (rawItem['meters'] as num?)?.toInt() ?? 0;
    var title = (rawItem['title'] as String?)?.trim() ?? '';
    if (title.isEmpty && meters > 0) title = '$meters м';
    final subtitle = (rawItem['subtitle'] as String?)?.trim() ?? '';
    var idx = (rawItem['intensityIndex'] as num?)?.toInt() ?? 2;
    if (idx < 0 || idx > 3) idx = 2;
    final storedLabel = (rawItem['intensityLabel'] as String?)?.trim() ?? '';
    out.add(
      _WorkoutSetItem(
        title: title.isEmpty ? 'Сет' : title,
        subtitle: subtitle,
        meters: meters,
        intensityIndex: idx,
        intensityLabel: storedLabel.isNotEmpty ? storedLabel : SwimflowIntensity.labelRu(idx),
      ),
    );
  }
  return out;
}

class StitchWorkoutDetailScreen extends ConsumerWidget {
  const StitchWorkoutDetailScreen({
    required this.workoutId,
    super.key,
    this.athleteUid,
  });

  final String workoutId;
  final String? athleteUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = athleteUid != null && athleteUid!.isNotEmpty
        ? ref.watch(coachAthleteWorkoutsFamily(athleteUid!))
        : ref.watch(swimflowWorkoutsProvider);

    return Scaffold(
      body: StitchPageScaffold(
        bottomInset: 32,
        child: async.when(
          data: (list) {
            SwimflowWorkout? w;
            for (final x in list) {
              if (x.id == workoutId) {
                w = x;
                break;
              }
            }
            if (w == null) {
              return Center(child: Text('Тренировка не найдена', style: Theme.of(context).textTheme.titleMedium));
            }
            return _DetailBody(workout: w, coachView: athleteUid != null && athleteUid!.isNotEmpty);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.workout, required this.coachView});

  final SwimflowWorkout workout;
  final bool coachView;

  @override
  Widget build(BuildContext context) {
    final zones = _intensitySlices(workout);
    final strokes = _strokeSlices(workout);
    final sets = _workoutSets(workout);
    return Column(
      children: [
        const StitchSubpageHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('d MMMM yyyy', 'ru').format(workout.scheduledAt),
                          style: GoogleFonts.lexend(
                            fontSize: 13,
                            color: StitchColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(workout.title, style: Theme.of(context).textTheme.headlineMedium),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: StitchColors.primaryFixed,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _formatWorkoutDurationShort(workout.durationSeconds),
                      style: GoogleFonts.lexend(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF001A41),
                      ),
                    ),
                  ),
                ],
              ),
              if (workout.poolName.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 18, color: StitchColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      workout.poolName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: StitchColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 132,
                      child: _glassMetric(context, Icons.pool_rounded, StitchColors.primary, 'Дистанция',
                          workout.distanceMeters.toStringAsFixed(0), 'м', '${workout.laps} кругов'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 132,
                      child: _glassMetric(
                          context,
                          Icons.local_fire_department_outlined,
                          StitchColors.onSecondaryContainer,
                          'Калории',
                          '${workout.displayKcal}',
                          'ккал',
                          'Активные'),
                    ),
                  ),
                ],
              ),
              if (sets.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Сеты', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (var i = 0; i < sets.length; i++) ...[
                  if (i > 0) const SizedBox(height: 10),
                  _setRow(context, sets[i], i + 1),
                ],
              ],
              if (strokes.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Стиль по дистанции', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                StitchGlassCard(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          height: 12,
                          child: Row(
                            children: [
                              for (var i = 0; i < strokes.length; i++)
                                Expanded(
                                  flex: (strokes[i].fraction * 1000).round().clamp(1, 1000),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: i.isEven ? StitchColors.primary : StitchColors.secondaryFixedDim,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      for (var i = 0; i < strokes.length; i++) ...[
                        if (i > 0) Divider(color: StitchColors.surfaceContainer),
                        _strokeRow(
                          strokes[i].name,
                          '${(strokes[i].fraction * workout.distanceMeters).round()} м',
                          '${strokes[i].percent}%',
                          i.isEven ? StitchColors.primary : StitchColors.secondaryFixedDim,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Text('Зоны интенсивности', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              if (zones.isEmpty)
                StitchGlassCard(
                  child: Text(
                    'Нет данных по сетам. Новые тренировки сохраняют интенсивность автоматически.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: StitchColors.onSurfaceVariant),
                  ),
                )
              else
                ...List.generate(zones.length, (i) {
                  final z = zones[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: i < zones.length - 1 ? 10 : 0),
                    child: _zoneRow(z.label, z.fraction, z.color, '${z.percent}%'),
                  );
                }),
              const SizedBox(height: 24),
              WorkoutWellbeingPanel(
                workoutId: workout.id,
                scheduledAt: workout.scheduledAt,
                recordMeta: workout.recordMeta,
                readOnly: coachView,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _glassMetric(
    BuildContext context,
    IconData icon,
    Color iconColor,
    String cap,
    String main,
    String unit,
    String sub,
  ) {
    return StitchGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  cap.toUpperCase(),
                  style: GoogleFonts.lexend(fontSize: 11, color: iconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(main, style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Text(unit, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          Text(sub, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _setRow(BuildContext context, _WorkoutSetItem set, int index) {
    return StitchGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: StitchColors.primaryFixed,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$index',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: StitchColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(set.title, style: Theme.of(context).textTheme.titleMedium),
                if (set.subtitle.isNotEmpty)
                  Text(
                    set.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: StitchColors.onSurfaceVariant,
                        ),
                  ),
                Text(
                  set.intensityLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StitchColors.outline,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${set.meters} м',
                style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _strokeRow(String name, String sub, String pct, Color dot) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(sub, style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant)),
              ],
            ),
          ),
          Text(pct, style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _zoneRow(String z, double frac, Color c, String pctText) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            z,
            textAlign: TextAlign.right,
            style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bc) {
              return SizedBox(
                height: 8,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: StitchColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    Container(
                      width: bc.maxWidth * frac,
                      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(999)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 44,
          child: Text(pctText, style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
