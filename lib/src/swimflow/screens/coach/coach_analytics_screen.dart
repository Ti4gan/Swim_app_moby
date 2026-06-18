import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/competition_swim.dart';
import '../../models/rank_norm_entry.dart';
import '../../models/swimflow_sport_rank.dart';
import '../../models/training_analysis.dart';
import '../../providers/swimflow_providers.dart';
import '../../providers/training_analysis_providers.dart';
import '../../theme/coach_theme.dart';
import '../../widgets/coach_widgets.dart';
import '../../widgets/performance_goal_panel.dart';

class CoachAnalyticsScreen extends ConsumerStatefulWidget {
  const CoachAnalyticsScreen({super.key});

  @override
  ConsumerState<CoachAnalyticsScreen> createState() => _CoachAnalyticsScreenState();
}

class _CoachAnalyticsScreenState extends ConsumerState<CoachAnalyticsScreen> {
  String? _athleteId;
  String? _selectedGoalId;

  @override
  Widget build(BuildContext context) {
    final athletesAsync = ref.watch(coachAthletesProvider);

    return Scaffold(
      body: CoachPageBackground(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CoachFlowHeader(),
            Expanded(
              child: athletesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (list) {
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        'Нет пловцов в группе',
                        style: GoogleFonts.inter(color: CoachColors.onSurfaceVariant),
                      ),
                    );
                  }
                  final sorted = [...list]..sort((a, b) => a.displayName.compareTo(b.displayName));
                  final selectedId = _athleteId ?? sorted.first.uid;
                  if (_athleteId == null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _athleteId = sorted.first.uid);
                    });
                  }

                  final goalsAsync = ref.watch(athletePerformanceGoalsFamily(selectedId));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: CoachGlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: selectedId,
                              isExpanded: true,
                              items: [
                                for (final a in sorted)
                                  DropdownMenuItem(
                                    value: a.uid,
                                    child: Text(
                                      a.displayName,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: (v) {
                                setState(() {
                                  _athleteId = v;
                                  _selectedGoalId = null;
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          children: [
                            PerformanceGoalPanel(
                              athleteUid: selectedId,
                              coachMode: true,
                              useCoachTheme: true,
                              embedded: true,
                              externalGoalId: _selectedGoalId,
                              onGoalChanged: (id) => setState(() => _selectedGoalId = id),
                            ),
                            const SizedBox(height: 20),
                            goalsAsync.when(
                              loading: () => const SizedBox(
                                height: 100,
                                child: Center(child: CircularProgressIndicator(strokeWidth: 3)),
                              ),
                              error: (e, _) => Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Text('Ошибка загрузки целей: $e'),
                              ),
                              data: (goals) {
                                final selectedGoal = _selectedGoalId != null
                                    ? goals.where((g) => g.id == _selectedGoalId).firstOrNull
                                    : goals.firstOrNull;
                                if (selectedGoal == null) return const SizedBox.shrink();
                                final athleteRank = sorted.where((a) => a.uid == selectedId).firstOrNull?.sportRankId ?? '';
                                return _TrainingAnalysisSection(
                                  athleteUid: selectedId,
                                  distanceMeters: selectedGoal.distanceMeters,
                                  strokeKey: selectedGoal.strokeKey,
                                  sportRankId: athleteRank,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _TrainingAnalysisSection extends ConsumerWidget {
  const _TrainingAnalysisSection({
    required this.athleteUid,
    required this.distanceMeters,
    required this.strokeKey,
    required this.sportRankId,
  });

  final String athleteUid;
  final int distanceMeters;
  final String strokeKey;
  final String sportRankId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyses = ref.watch(trainingAnalysisProvider(athleteUid));
    final filtered = analyses.where((a) => a.distanceMeters == distanceMeters && a.strokeKey == strokeKey).toList();
    final normsAsync = ref.watch(rankNormsProvider);
    final swimsAsync = ref.watch(athleteCompetitionSwimsFamily(athleteUid));

    final nextRankGap = _computeNextRankGap(
      sportRankId: sportRankId,
      distanceMeters: distanceMeters,
      strokeKey: strokeKey,
      norms: normsAsync.valueOrNull ?? {},
      swims: swimsAsync.valueOrNull ?? [],
    );

    final widgets = <Widget>[
      if (filtered.isEmpty && nextRankGap == null)
        CoachGlassCard(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'Недостаточно данных для анализа дистанции $distanceMeters м.\nНужно минимум 2 результата на соревнованиях.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: CoachColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      if (nextRankGap != null)
        _NextRankCard(
          nextRankLabel: nextRankGap.$1,
          gapSeconds: nextRankGap.$2,
          centisecondsToNext: nextRankGap.$3,
          bestTimeSeconds: nextRankGap.$4,
          normTimeSeconds: nextRankGap.$5,
          normMet: nextRankGap.$6,
          noResults: nextRankGap.$7,
        ),
      if (filtered.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Text(
            'Анализатор эффективности тренировок',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: CoachColors.onBackground,
            ),
          ),
        ),
        ...filtered.map((a) => _AnalysisCard(analysis: a)),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}

(String, double, int, double, double, bool, bool)?
    _computeNextRankGap({
  required String sportRankId,
  required int distanceMeters,
  required String strokeKey,
  required Map<String, List<RankNormEntry>> norms,
  required List<CompetitionSwim> swims,
}) {
  if (sportRankId.isEmpty) {
    print('[RANK] sportRankId is empty');
    return null;
  }

  final idx = SwimflowSportRank.orderedIds.indexOf(sportRankId);
  print('[RANK] sportRankId=$sportRankId idx=$idx');
  if (idx <= 0) {
    print('[RANK] already highest rank or not found');
    return null;
  }

  final nextRankId = SwimflowSportRank.orderedIds[idx - 1];
  print('[RANK] nextRankId=$nextRankId');

  print('[RANK] norms keys=${norms.keys.join(',')}');
  final normEntries = norms[nextRankId] ?? [];
  print('[RANK] normEntries count=${normEntries.length}');
  for (final e in normEntries) {
    print('[RANK]  entry: distance=${e.distanceMeters} stroke=${e.strokeKey} time=${e.timeCentiseconds}');
  }

  final norm = normEntries.where(
    (e) => e.distanceMeters == distanceMeters && e.strokeKey == strokeKey,
  ).firstOrNull;
  if (norm == null) {
    print('[RANK] no norm for distance=$distanceMeters stroke=$strokeKey');
    return null;
  }

  print('[RANK] found norm: ${norm.timeCentiseconds}cs');

  final best = swims
      .where((s) => s.distanceMeters == distanceMeters && s.strokeKey == strokeKey)
      .fold<int>(9999999, (min, s) => s.timeCentiseconds < min ? s.timeCentiseconds : min);

  final nextRankLabel = SwimflowSportRank.labelRu(nextRankId);
  final normSeconds = norm.timeCentiseconds / 100.0;

  if (best >= 9999999) {
    print('[RANK] no swims for this distance+stroke');
    return (nextRankLabel, 0.0, 0, 0.0, normSeconds, false, true);
  }

  final gapCentiseconds = best - norm.timeCentiseconds;
  final gapSeconds = gapCentiseconds / 100.0;
  final bestSeconds = best / 100.0;
  final normMet = gapCentiseconds <= 0;

  print('[RANK] gap=${gapSeconds}s normMet=$normMet');
  return (nextRankLabel, gapSeconds.abs(), gapCentiseconds.abs(), bestSeconds, normSeconds, normMet, false);
}

class _NextRankCard extends StatelessWidget {
  const _NextRankCard({
    required this.nextRankLabel,
    required this.gapSeconds,
    required this.centisecondsToNext,
    required this.bestTimeSeconds,
    required this.normTimeSeconds,
    required this.normMet,
    required this.noResults,
  });

  final String nextRankLabel;
  final double gapSeconds;
  final int centisecondsToNext;
  final double bestTimeSeconds;
  final double normTimeSeconds;
  final bool normMet;
  final bool noResults;

  @override
  Widget build(BuildContext context) {
    final borderColor = normMet
        ? const Color(0xFF2E7D32)
        : CoachColors.secondaryContainer.withValues(alpha: 0.35);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: normMet ? const Color(0xFF2E7D32).withValues(alpha: 0.06) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  normMet ? Icons.check_circle_rounded : Icons.emoji_events_rounded,
                  color: normMet ? const Color(0xFF2E7D32) : CoachColors.primaryContainer,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'До следующего разряда',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: normMet ? const Color(0xFF2E7D32) : CoachColors.onBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: normMet
                          ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                          : CoachColors.primaryContainer.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      nextRankLabel,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: normMet ? const Color(0xFF2E7D32) : CoachColors.primaryContainer,
                      ),
                    ),
                  ),
                ),
                if (!noResults) ...[
                  const SizedBox(width: 12),
                  Text(
                    normMet ? '✓ Выполнен' : SwimflowSportRank.formatSeconds(gapSeconds),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: normMet ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ],
              ],
            ),
            if (!noResults) ...[
              const SizedBox(height: 8),
              Text(
                normMet
                    ? 'Лучший: ${SwimflowSportRank.formatSeconds(bestTimeSeconds)} · Норматив: ${SwimflowSportRank.formatSeconds(normTimeSeconds)}'
                    : 'Текущий лучший: ${SwimflowSportRank.formatSeconds(bestTimeSeconds)} · Норматив: ${SwimflowSportRank.formatSeconds(normTimeSeconds)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CoachColors.onSurfaceVariant,
                ),
              ),
            ],
            if (noResults) ...[
              const SizedBox(height: 8),
              Text(
                'Нет результатов на этой дистанции · Норматив: ${SwimflowSportRank.formatSeconds(normTimeSeconds)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: CoachColors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  const _AnalysisCard({required this.analysis});

  final TrainingAnalysis analysis;

  String _strokeLabel() {
    const labels = {'free': 'Вольный стиль', 'breast': 'Брасс', 'back': 'На спине', 'fly': 'Баттерфляй', 'im': 'Комплекс'};
    return labels[analysis.strokeKey] ?? analysis.strokeKey;
  }

  String _efficiencyLabel() {
    switch (analysis.efficiencyLevel) {
      case 'high':
        return 'Высокая';
      case 'medium':
        return 'Средняя';
      case 'low':
        return 'Низкая';
      default:
        return 'Отрицательная';
    }
  }

  Color _efficiencyColor() {
    switch (analysis.efficiencyLevel) {
      case 'high':
        return const Color(0xFF2E7D32);
      case 'medium':
        return const Color(0xFFF57F17);
      case 'low':
        return const Color(0xFFFF6F00);
      default:
        return const Color(0xFFC62828);
    }
  }

  String _improvementSign() {
    if (analysis.improvementInSeconds > 0) return '+';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'ru');
    final secFormat = NumberFormat('#0.00', 'ru');
    final pctFormat = NumberFormat('#0.0', 'ru');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CoachGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.speed_rounded, color: CoachColors.primaryContainer, size: 22),
                const SizedBox(width: 8),
                Text(
                  '${analysis.distanceMeters} м · ${_strokeLabel()}',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: CoachColors.onBackground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _DataRow(label: 'Предыдущий результат', value: '${secFormat.format(analysis.previousResultSeconds)} с'),
            _DataRow(label: 'Новый результат', value: '${secFormat.format(analysis.currentResultSeconds)} с'),
            _DataRow(label: 'Тренировок в цикле', value: '${analysis.workoutsCount}'),
            _DataRow(
              label: 'Улучшение',
              value: '${_improvementSign()}${secFormat.format(analysis.improvementInSeconds)} с',
              valueColor: analysis.improvementInSeconds >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
            _DataRow(
              label: 'Прогресс',
              value: '${_improvementSign()}${pctFormat.format(analysis.progressPercent)}%',
              valueColor: analysis.progressPercent >= 0 ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
            ),
            _DataRow(label: 'Эффективность тренировки', value: '${pctFormat.format(analysis.averageWorkoutEfficiency)}%'),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  'Эффективность: ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: CoachColors.onSurfaceVariant,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _efficiencyColor().withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _efficiencyLabel(),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _efficiencyColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${dateFormat.format(analysis.startDate)} — ${dateFormat.format(analysis.endDate)}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: CoachColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: CoachColors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? CoachColors.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}
