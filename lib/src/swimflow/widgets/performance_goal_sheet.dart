import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/performance_goal_logic.dart';
import '../logic/training_input_limits.dart';
import '../models/competition_swim.dart';
import '../models/performance_goal.dart';
import '../providers/swimflow_providers.dart';
import '../theme/coach_theme.dart';
import 'competition_swims_panel.dart';

enum PerformanceGoalSheetMode { add, edit }

Future<bool?> showPerformanceGoalSheet({
  required BuildContext context,
  required PerformanceGoalSheetMode mode,
  required String athleteUid,
  required List<PerformanceGoal> existingGoals,
  PerformanceGoal? editGoal,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => PerformanceGoalSheet(
      mode: mode,
      athleteUid: athleteUid,
      existingGoals: existingGoals,
      editGoal: editGoal,
    ),
  );
}

class PerformanceGoalSheet extends ConsumerStatefulWidget {
  const PerformanceGoalSheet({
    required this.mode,
    required this.athleteUid,
    required this.existingGoals,
    this.editGoal,
    super.key,
  });

  final PerformanceGoalSheetMode mode;
  final String athleteUid;
  final List<PerformanceGoal> existingGoals;
  final PerformanceGoal? editGoal;

  bool get isEdit => mode == PerformanceGoalSheetMode.edit;

  @override
  ConsumerState<PerformanceGoalSheet> createState() => _PerformanceGoalSheetState();
}

class _PerformanceGoalSheetState extends ConsumerState<PerformanceGoalSheet> {
  late String _stroke;
  late int _distance;
  late int _pool;
  final _targetTime = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final g = widget.editGoal;
    if (g != null) {
      _stroke = g.strokeKey;
      _distance = g.distanceMeters;
      _pool = g.poolLengthMeters;
      _targetTime.text = formatTimeCentiseconds(g.targetTimeCentiseconds);
    } else {
      _stroke = 'free';
      _distance = 100;
      _pool = 25;
    }
  }

  @override
  void dispose() {
    _targetTime.dispose();
    super.dispose();
  }

  PerformanceGoal? _goalForForm() {
    final docId = PerformanceGoal.docIdFor(
      strokeKey: _stroke,
      distanceMeters: _distance,
      poolLengthMeters: _pool,
    );
    return widget.existingGoals.where((g) => g.id == docId).firstOrNull;
  }

  Future<void> _save() async {
    final repo = ref.read(coachRepositoryProvider);
    if (repo == null) return;
    final cs = parseTimeCentisecondsInput(_targetTime.text);
    if (cs == null || cs <= 0) {
      setState(() => _error = 'Укажите время в формате мм:сс,сс');
      return;
    }
    final newId = PerformanceGoal.docIdFor(
      strokeKey: _stroke,
      distanceMeters: _distance,
      poolLengthMeters: _pool,
    );
    if (!widget.isEdit) {
      if (_goalForForm() != null) {
        setState(() => _error = 'Цель на эту дистанцию уже задана');
        return;
      }
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await repo.setAthletePerformanceGoal(
        athleteUid: widget.athleteUid,
        strokeKey: _stroke,
        distanceMeters: _distance,
        poolLengthMeters: _pool,
        targetTimeCentiseconds: cs,
      );
      final original = widget.editGoal;
      if (widget.isEdit && original != null && original.id != newId) {
        await repo.clearAthletePerformanceGoal(
          athleteUid: widget.athleteUid,
          strokeKey: original.strokeKey,
          distanceMeters: original.distanceMeters,
          poolLengthMeters: original.poolLengthMeters,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final g = widget.editGoal;
    if (g == null) return;
    final repo = ref.read(coachRepositoryProvider);
    if (repo == null) return;
    setState(() => _saving = true);
    try {
      await repo.clearAthletePerformanceGoal(
        athleteUid: widget.athleteUid,
        strokeKey: g.strokeKey,
        distanceMeters: g.distanceMeters,
        poolLengthMeters: g.poolLengthMeters,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final distances = competitionDistancesMetersByStroke[_stroke] ?? [100];
    if (!distances.contains(_distance)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _distance = distances.first);
      });
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CoachColors.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: CoachColors.onBackground,
                      ),
                    ),
                    Text(
                      widget.isEdit ? 'Изменить цель' : 'Добавить цель',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: CoachColors.onBackground,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionLabel('СТИЛЬ'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in competitionStrokeLabelsRu.entries)
                      _SheetChip(
                        label: e.value,
                        selected: _stroke == e.key,
                        onTap: _saving ? null : () => setState(() => _stroke = e.key),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionLabel('ДИСТАНЦИЯ'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final d in distances)
                      _SheetChip(
                        label: '$d м',
                        selected: _distance == d,
                        onTap: _saving ? null : () => setState(() => _distance = d),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                _sectionLabel('БАССЕЙН'),
                const SizedBox(height: 10),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 25, label: Text('25 м')),
                    ButtonSegment(value: 50, label: Text('50 м')),
                  ],
                  selected: {_pool},
                  onSelectionChanged: _saving
                      ? null
                      : (s) => setState(() => _pool = s.first),
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) return Colors.white;
                      return CoachColors.surfaceContainerLow;
                    }),
                    foregroundColor: WidgetStateProperty.all(CoachColors.onBackground),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionLabel('ЦЕЛЕВОЕ ВРЕМЯ'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: CoachColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _targetTime,
                    enabled: !_saving,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CompetitionTimeTextInputFormatter()],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: CoachColors.primaryContainer,
                      letterSpacing: -0.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '00:54,78',
                      hintStyle: TextStyle(color: Color(0xFFB0B5C0)),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Color(0xFFBA1A1A), fontSize: 13)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: CoachColors.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          widget.isEdit ? 'Сохранить изменения' : 'Добавить цель',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
                if (widget.isEdit) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _saving ? null : _delete,
                    child: Text(
                      'Снять цель',
                      style: GoogleFonts.inter(color: const Color(0xFFBA1A1A), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: CoachColors.onSurfaceVariant,
      ),
    );
  }
}

class _SheetChip extends StatelessWidget {
  const _SheetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE8F0FF) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? CoachColors.primaryContainer : CoachColors.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? CoachColors.primaryContainer : CoachColors.onBackground,
            ),
          ),
        ),
      ),
    );
  }
}
