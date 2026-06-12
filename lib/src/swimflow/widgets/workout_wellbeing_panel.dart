import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/firestore_messages.dart';
import '../logic/workout_wellbeing.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import 'stitch_widgets.dart';

class WorkoutWellbeingPanel extends ConsumerStatefulWidget {
  const WorkoutWellbeingPanel({
    required this.workoutId,
    required this.scheduledAt,
    required this.recordMeta,
    this.readOnly = false,
    super.key,
  });

  final String workoutId;
  final DateTime scheduledAt;
  final Map<String, dynamic>? recordMeta;
  final bool readOnly;

  @override
  ConsumerState<WorkoutWellbeingPanel> createState() => _WorkoutWellbeingPanelState();
}

class _WorkoutWellbeingPanelState extends ConsumerState<WorkoutWellbeingPanel> {
  late int _mood;
  late double _fatigue;
  late String _physical;
  late bool _editing;
  bool _saving = false;
  bool _optimisticSaved = false;

  bool get _isFuture => isWorkoutScheduledInFuture(widget.scheduledAt);

  bool get _saved => swimmerWellbeingReported(widget.recordMeta) || _optimisticSaved;

  String get _title => widget.readOnly ? 'Состояние пловца' : 'Ваше состояние';

  Widget _moodNotSpecifiedCard(BuildContext context) {
    return StitchGlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.sentiment_neutral_outlined, color: StitchColors.onSurfaceVariant.withValues(alpha: 0.85)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Настроение не указано',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: StitchColors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _readMeta(widget.recordMeta);
    _editing = !widget.readOnly && !_isFuture && !_saved;
  }

  @override
  void didUpdateWidget(WorkoutWellbeingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recordMeta != widget.recordMeta) {
      _readMeta(widget.recordMeta);
      if (swimmerWellbeingReported(widget.recordMeta)) {
        _optimisticSaved = false;
        _editing = false;
      }
    }
  }

  void _readMeta(Map<String, dynamic>? meta) {
    _mood = parseWorkoutMoodIndex(meta);
    _fatigue = parseWorkoutFatigue(meta).toDouble();
    _physical = parseWorkoutPhysicalState(meta);
  }

  Future<void> _save() async {
    final repo = ref.read(swimflowRepositoryProvider);
    if (repo == null) return;
    setState(() => _saving = true);
    try {
      await repo.updateWorkoutWellbeing(
        workoutId: widget.workoutId,
        moodIndex: _mood,
        fatigue01to10: _fatigue.round().clamp(1, 10),
        physicalState: _physical,
      );
      if (mounted) {
        setState(() {
          _optimisticSaved = true;
          _editing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(swimFirestoreMessageRu(e, saving: true))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.readOnly) {
      if (!_saved) {
        return _moodNotSpecifiedCard(context);
      }
      return _SavedSummary(
        title: _title,
        moodIndex: _mood,
        fatigue: _fatigue.round(),
        physical: _physical,
        savedLabel: 'Состояние указано пловцом',
        onEdit: null,
      );
    }

    if (_isFuture) {
      return StitchGlassCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.event_busy_rounded, color: StitchColors.onSurfaceVariant.withValues(alpha: 0.8)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Состояние после тренировки можно указать в день тренировки или позже.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: StitchColors.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_editing && _saved) {
      return _SavedSummary(
        title: _title,
        moodIndex: _mood,
        fatigue: _fatigue.round(),
        physical: _physical,
        savedLabel: widget.readOnly ? 'Состояние указано пловцом' : 'Настроение сохранено',
        onEdit: widget.readOnly ? null : () => setState(() => _editing = true),
      );
    }

    return StitchGlassCard(
      child: AbsorbPointer(
        absorbing: _saving,
        child: Opacity(
          opacity: _saving ? 0.55 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Text(
                'КАК ВАШЕ НАСТРОЕНИЕ?',
                style: GoogleFonts.lexend(fontSize: 11, color: StitchColors.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (i) {
                  final sel = i == _mood;
                  return GestureDetector(
                    onTap: _saving ? null : () => setState(() => _mood = i),
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel ? StitchColors.primaryFixed : StitchColors.surfaceContainer,
                            border: Border.all(
                              color: sel ? StitchColors.primary : StitchColors.outlineVariant,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(workoutMoodEmojis[i], style: const TextStyle(fontSize: 24)),
                        ),
                        if (sel) ...[
                          const SizedBox(height: 4),
                          Text(
                            workoutMoodLabelsRu[i],
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: StitchColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'УРОВЕНЬ УСТАЛОСТИ',
                    style: GoogleFonts.lexend(fontSize: 11, color: StitchColors.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    '${_fatigue.round()} / 10',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: StitchColors.primary,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _fatigue,
                min: 1,
                max: 10,
                divisions: 9,
                activeColor: StitchColors.primary,
                onChanged: _saving ? null : (v) => setState(() => _fatigue = v),
              ),
              const SizedBox(height: 8),
              Text(
                'ФИЗИЧЕСКОЕ СОСТОЯНИЕ',
                style: GoogleFonts.lexend(fontSize: 11, color: StitchColors.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _physChip('Уставший', 'tired')),
                  const SizedBox(width: 8),
                  Expanded(child: _physChip('Нормально', 'normal')),
                  const SizedBox(width: 8),
                  Expanded(child: _physChip('Энергичный', 'energy')),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: StitchColors.primaryContainer,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Сохранить состояние', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _physChip(String label, String value) {
    final sel = _physical == value;
    return Material(
      color: sel ? StitchColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _saving ? null : () => setState(() => _physical = value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? StitchColors.primary : StitchColors.outlineVariant),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: sel ? Colors.white : StitchColors.onBackground,
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedSummary extends StatelessWidget {
  const _SavedSummary({
    required this.title,
    required this.moodIndex,
    required this.fatigue,
    required this.physical,
    required this.savedLabel,
    this.onEdit,
  });

  final String title;
  final int moodIndex;
  final int fatigue;
  final String physical;
  final String savedLabel;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final moodIdx = moodIndex.clamp(0, 4);
    return StitchGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  color: StitchColors.primary,
                  tooltip: 'Изменить',
                ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 18, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  savedLabel,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(workoutMoodEmojis[moodIdx], style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workoutMoodLabelsRu[moodIdx],
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: StitchColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _summaryLine('Усталость', '$fatigue / 10'),
                    const SizedBox(height: 4),
                    _summaryLine('Физическое состояние', physicalStateLabelRu(physical)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String cap, String value) {
    return Row(
      children: [
        Text(
          '$cap: ',
          style: GoogleFonts.lexend(fontSize: 13, color: StitchColors.onSurfaceVariant),
        ),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: StitchColors.onBackground,
          ),
        ),
      ],
    );
  }
}
