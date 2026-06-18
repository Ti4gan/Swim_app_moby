import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../logic/performance_goal_logic.dart';
import '../models/competition_swim.dart';
import '../models/performance_goal.dart';
import '../providers/swimflow_providers.dart';
import '../theme/coach_theme.dart';
import '../theme/tokens.dart';
import 'competition_swims_panel.dart';
import 'performance_goal_chart.dart';
import 'performance_goal_sheet.dart';
import 'stitch_widgets.dart';

class PerformanceGoalPanel extends ConsumerStatefulWidget {
  const PerformanceGoalPanel({
    required this.athleteUid,
    required this.coachMode,
    super.key,
    this.useCoachTheme = false,
    this.embedded = false,
    this.externalGoalId,
    this.onGoalChanged,
  });

  final String athleteUid;
  final bool coachMode;
  final bool useCoachTheme;
  final bool embedded;
  final String? externalGoalId;
  final ValueChanged<String?>? onGoalChanged;

  @override
  ConsumerState<PerformanceGoalPanel> createState() => _PerformanceGoalPanelState();
}

class _PerformanceGoalPanelState extends ConsumerState<PerformanceGoalPanel> {
  String? _selectedGoalId;

  Color get _primary => widget.useCoachTheme ? CoachColors.primaryContainer : StitchColors.primary;
  Color get _onVariant =>
      widget.useCoachTheme ? CoachColors.onSurfaceVariant : StitchColors.onSurfaceVariant;

  String _goalLabel(PerformanceGoal g) =>
      '${competitionStrokeRu(g.strokeKey)} · ${g.distanceMeters} м · ${g.poolLengthMeters} м';

  String _formatGapShort(int centiseconds) {
    if (centiseconds <= 0) return '0,00';
    if (centiseconds < 6000) {
      return (centiseconds / 100).toStringAsFixed(2).replaceAll('.', ',');
    }
    return formatTimeCentiseconds(centiseconds);
  }

  String? get _goalId => widget.externalGoalId ?? _selectedGoalId;

  PerformanceGoal? _pickSelected(List<PerformanceGoal> goals) {
    if (goals.isEmpty) return null;
    final hit = goals.where((g) => g.id == _goalId).firstOrNull;
    return hit ?? goals.first;
  }

  void _syncSelection(List<PerformanceGoal> goals) {
    if (widget.externalGoalId != null) return;
    if (goals.isEmpty) {
      _selectedGoalId = null;
      return;
    }
    if (_selectedGoalId == null || !goals.any((g) => g.id == _selectedGoalId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedGoalId = goals.first.id);
      });
    }
  }

  void _selectGoal(String id) {
    if (widget.onGoalChanged != null) {
      widget.onGoalChanged!(id);
    } else {
      setState(() => _selectedGoalId = id);
    }
  }

  Future<void> _openSheet({required PerformanceGoalSheetMode mode, PerformanceGoal? editGoal}) async {
    final goals = ref.read(athletePerformanceGoalsFamily(widget.athleteUid)).valueOrNull ?? [];
    final ok = await showPerformanceGoalSheet(
      context: context,
      mode: mode,
      athleteUid: widget.athleteUid,
      existingGoals: goals,
      editGoal: editGoal,
    );
    if (ok == true && mounted && editGoal != null) {
      _selectGoal(editGoal.id);
    }
  }

  Widget _card({required Widget child}) {
    if (widget.useCoachTheme) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CoachColors.secondaryContainer.withValues(alpha: 0.35)),
        ),
        child: child,
      );
    }
    return StitchGlassCard(child: child);
  }

  Widget _buildGoalPicker(List<PerformanceGoal> goals, PerformanceGoal selected) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final g in goals) ...[
            _GoalPickerTile(
              label: _goalLabel(g),
              selected: g.id == selected.id,
              coachStyle: widget.useCoachTheme,
              onTap: () => _selectGoal(g.id),
            ),
            if (g != goals.last) const SizedBox(height: 8),
          ],
          if (widget.coachMode) ...[
            const SizedBox(height: 8),
            Material(
              color: widget.useCoachTheme
                  ? CoachColors.surfaceContainerLow
                  : StitchColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _openSheet(mode: PerformanceGoalSheetMode.add),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Text(
                      'Добавить еще',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: widget.useCoachTheme ? CoachColors.onSurfaceVariant : _onVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgress(PerformanceGoalProgress progress) {
    final g = progress.goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _metricTile(
                'Цель',
                formatTimeCentiseconds(g.targetTimeCentiseconds),
                Icons.flag_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile(
                'Лучший',
                progress.bestTimeCentiseconds == null
                    ? '—'
                    : formatTimeCentiseconds(progress.bestTimeCentiseconds!),
                Icons.emoji_events_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _card(
          child: progress.achieved
              ? Center(
                  child: Text(
                    'Цель выполнена',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.adjust_rounded, color: _primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'До цели',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: widget.useCoachTheme
                                  ? CoachColors.onBackground
                                  : StitchColors.onBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      progress.bestTimeCentiseconds == null
                          ? 'Добавьте заплыв на соревновании с этой дистанцией — появится график и расчёт.'
                          : 'Нужно улучшить ещё на ${_formatGapShort(progress.gapCentiseconds)}.',
                      style: TextStyle(color: _primary, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Динамика результата',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                progress.points.isEmpty ? 'Пока нет точек на графике' : '${progress.points.length} стартов',
                style: TextStyle(color: _onVariant, fontSize: 12),
              ),
              const SizedBox(height: 16),
              PerformanceGoalChart(progress: progress, primary: _primary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metricTile(String cap, String val, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.useCoachTheme
              ? CoachColors.secondaryContainer.withValues(alpha: 0.35)
              : StitchColors.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(height: 8),
          Text(
            cap.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: _primary),
          ),
          Text(
            val,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: widget.useCoachTheme ? CoachColors.onBackground : StitchColors.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCoach() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Задайте цель пловцу по результату на дистанции',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: _onVariant, fontSize: 15),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openSheet(mode: PerformanceGoalSheetMode.add),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: CoachColors.primaryContainer,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Задать цель'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(List<PerformanceGoal> goals, List<CompetitionSwim> swims) {
    _syncSelection(goals);
    final selected = _pickSelected(goals);
    if (selected == null) {
      return widget.coachMode ? _emptyCoach() : _scroll([
        _card(
          child: Text(
            'Тренер ещё не задал цель по результату на дистанции.',
            style: TextStyle(color: _onVariant),
          ),
        ),
      ]);
    }

    final progress = buildPerformanceGoalProgress(goal: selected, swims: swims);

    final content = _scroll([
      _buildGoalPicker(goals, selected),
      const SizedBox(height: 12),
      _buildProgress(progress),
    ]);

    if (!widget.coachMode || widget.embedded) {
      return content;
    }

    return Stack(
      children: [
        content,
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _openSheet(mode: PerformanceGoalSheetMode.edit, editGoal: selected),
            backgroundColor: CoachColors.primaryContainer,
            elevation: 4,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            label: Text(
              'Изменить',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _scroll(List<Widget> children) {
    final padH = widget.useCoachTheme ? 16.0 : 20.0;
    final bottom = widget.coachMode && !widget.embedded ? 88.0 : 96.0;
    if (widget.embedded) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(padH, 8, padH, bottom),
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(athletePerformanceGoalsFamily(widget.athleteUid));
    final swimsAsync = ref.watch(athleteCompetitionSwimsFamily(widget.athleteUid));

    return goalsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (goals) {
        return swimsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (swims) => _body(goals, swims),
        );
      },
    );
  }
}

class _GoalPickerTile extends StatelessWidget {
  const _GoalPickerTile({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.coachStyle,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool coachStyle;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? CoachColors.primaryContainer : Colors.white;
    final fg = selected ? Colors.white : (coachStyle ? CoachColors.onBackground : StitchColors.onBackground);
    final border = selected
        ? CoachColors.primaryContainer
        : (coachStyle ? CoachColors.outlineVariant : StitchColors.outline.withValues(alpha: 0.4));

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              if (selected) ...[
                const Icon(Icons.check_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

