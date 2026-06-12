import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../logic/workout_wellbeing.dart';
import '../models/linked_athlete.dart';
import '../models/swimflow_workout.dart';
import '../providers/data_refresh.dart';
import '../providers/swimflow_providers.dart';
import 'swimflow_refresh.dart';
import '../theme/coach_theme.dart';
import 'competition_swims_panel.dart';
import 'month_summary_bento.dart';
import 'profile_avatar.dart';

class CoachAthleteDetailHeader extends StatelessWidget {
  const CoachAthleteDetailHeader({
    required this.displayName,
    required this.onBack,
    this.athlete,
    super.key,
  });

  final String displayName;
  final VoidCallback onBack;
  final LinkedAthlete? athlete;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 12),
      child: SafeArea(
        bottom: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: CoachColors.primary),
            ),
            Expanded(
              child: Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: CoachColors.onBackground,
                ),
              ),
            ),
            if (athlete != null) _AthleteThumb(athlete: athlete!),
          ],
        ),
      ),
    );
  }
}

class _AthleteThumb extends StatelessWidget {
  const _AthleteThumb({required this.athlete});

  final LinkedAthlete athlete;

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (athlete.avatarUrl.isNotEmpty) {
      inner = Image.network(athlete.avatarUrl, fit: BoxFit.cover);
    } else if (ProfileAvatarPresets.isValid(athlete.avatarPreset)) {
      inner = ProfileAvatarPresets.tile(athlete.avatarPreset, 40);
    } else {
      inner = ColoredBox(
        color: CoachColors.secondaryContainer.withValues(alpha: 0.25),
        child: Center(
          child: Text(
            athlete.displayName.isNotEmpty ? athlete.displayName[0].toUpperCase() : '?',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: CoachColors.primary),
          ),
        ),
      );
    }
    return ClipOval(child: SizedBox(width: 40, height: 40, child: inner));
  }
}

class CoachAthleteViewTabs extends StatelessWidget {
  const CoachAthleteViewTabs({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final int selected;
  final ValueChanged<int> onChanged;

  static const _labels = ['Список', 'Календарь', 'Старты', 'Цель', 'Информация'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: CoachColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: List.generate(_labels.length, (i) {
            final sel = i == selected;
            return Expanded(
              child: Material(
                color: sel ? CoachColors.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => onChanged(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _labels[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : CoachColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class CoachSurfaceCard extends StatelessWidget {
  const CoachSurfaceCard({required this.child, super.key, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class CoachMonthCalendarCard extends StatefulWidget {
  const CoachMonthCalendarCard({
    required this.workouts,
    required this.onSelectedDayChanged,
    super.key,
    this.initialSelected,
  });

  final List<SwimflowWorkout> workouts;
  final ValueChanged<DateTime> onSelectedDayChanged;
  final DateTime? initialSelected;

  @override
  State<CoachMonthCalendarCard> createState() => _CoachMonthCalendarCardState();
}

class _CoachMonthCalendarCardState extends State<CoachMonthCalendarCard> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelected ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selected != null) widget.onSelectedDayChanged(_selected!);
    });
  }

  void _select(DateTime d) {
    setState(() => _selected = d);
    widget.onSelectedDayChanged(d);
  }

  bool _hasWorkout(DateTime d) {
    for (final w in widget.workouts) {
      if (w.scheduledAt.year == d.year &&
          w.scheduledAt.month == d.month &&
          w.scheduledAt.day == d.day) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final monthTitle = DateFormat('LLLL yyyy', 'ru').format(_month);
    final monthCapitalized = monthTitle[0].toUpperCase() + monthTitle.substring(1);

    return CoachSurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month - 1);
                }),
                icon: const Icon(Icons.chevron_left_rounded, color: CoachColors.primary),
              ),
              Expanded(
                child: Text(
                  monthCapitalized,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                onPressed: () => setState(() {
                  _month = DateTime(_month.year, _month.month + 1);
                }),
                icon: const Icon(Icons.chevron_right_rounded, color: CoachColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _CoachMonthGrid(
            month: _month,
            workouts: widget.workouts,
            selected: _selected,
            onSelect: _select,
            hasWorkout: _hasWorkout,
          ),
        ],
      ),
    );
  }
}

class _CoachMonthGrid extends StatelessWidget {
  const _CoachMonthGrid({
    required this.month,
    required this.workouts,
    required this.selected,
    required this.onSelect,
    required this.hasWorkout,
  });

  final DateTime month;
  final List<SwimflowWorkout> workouts;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;
  final bool Function(DateTime) hasWorkout;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    final startPad = first.weekday - 1;
    final daysInMonth = last.day;
    const labels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    final cells = <Widget>[];

    for (final l in labels) {
      cells.add(
        Center(
          child: Text(
            l,
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: CoachColors.onSurfaceVariant),
          ),
        ),
      );
    }

    final prevMonthLast = DateTime(month.year, month.month, 0).day;
    for (var i = 0; i < startPad; i++) {
      final dayNum = prevMonthLast - startPad + i + 1;
      cells.add(_coachDayCell(context, dayNum, muted: true, onTap: null));
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final isSel = selected != null &&
          selected!.year == date.year &&
          selected!.month == date.month &&
          selected!.day == date.day;
      final has = hasWorkout(date);
      final moodWorkout = latestPastWorkoutOnDay(workouts, date);
      cells.add(
        _coachDayCell(
          context,
          d,
          selected: isSel,
          hasDot: has && moodWorkout == null,
          moodWorkout: moodWorkout,
          onTap: () => onSelect(date),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, bc) {
        const spacing = 8.0;
        final cellW = (bc.maxWidth - 6 * spacing) / 7;
        const cellH = 58.0;
        final rows = <Widget>[];
        for (var i = 0; i < cells.length; i += 7) {
          final end = i + 7 <= cells.length ? i + 7 : cells.length;
          final chunk = cells.sublist(i, end);
          if (i > 0) rows.add(const SizedBox(height: spacing));
          rows.add(
            Row(
              children: [
                for (var j = 0; j < chunk.length; j++) ...[
                  if (j > 0) const SizedBox(width: spacing),
                  SizedBox(width: cellW, height: cellH, child: chunk[j]),
                ],
              ],
            ),
          );
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }

  Widget _coachDayCell(
    BuildContext context,
    int day, {
    bool muted = false,
    bool selected = false,
    bool hasDot = false,
    SwimflowWorkout? moodWorkout,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? CoachColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: hasDot && !selected
              ? Border.all(color: CoachColors.primaryContainer.withValues(alpha: 0.55), width: 2)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (muted ? CoachColors.onSurfaceVariant.withValues(alpha: 0.35) : CoachColors.onBackground),
              ),
            ),
            if (moodWorkout != null && !selected)
              Positioned(
                bottom: 4,
                child: WorkoutMoodEmoji(
                  recordMeta: moodWorkout.recordMeta,
                  scheduledAt: moodWorkout.scheduledAt,
                  size: 15,
                ),
              ),
            if (hasDot && !selected)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: CoachColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CoachAthleteCalendarPanel extends StatefulWidget {
  const CoachAthleteCalendarPanel({
    required this.workouts,
    required this.athleteId,
    required this.onSelectedDayChanged,
    super.key,
  });

  final List<SwimflowWorkout> workouts;
  final String athleteId;
  final ValueChanged<DateTime> onSelectedDayChanged;

  @override
  State<CoachAthleteCalendarPanel> createState() => _CoachAthleteCalendarPanelState();
}

class _CoachAthleteCalendarPanelState extends State<CoachAthleteCalendarPanel> {
  DateTime _selected = DateTime.now();

  List<SwimflowWorkout> _workoutsForDay(DateTime day) {
    final out = <SwimflowWorkout>[];
    for (final w in widget.workouts) {
      if (w.scheduledAt.year == day.year &&
          w.scheduledAt.month == day.month &&
          w.scheduledAt.day == day.day) {
        out.add(w);
      }
    }
    out.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      children: [
        CoachMonthCalendarCard(
          workouts: widget.workouts,
          onSelectedDayChanged: (d) {
            setState(() => _selected = d);
            widget.onSelectedDayChanged(d);
          },
        ),
        const SizedBox(height: 16),
        CoachAthleteDayPreview(
          day: _selected,
          workouts: _workoutsForDay(_selected),
          onWorkoutTap: (w) => context.push(
            '/workout/${w.id}?athleteId=${widget.athleteId}',
          ),
        ),
      ],
    );
  }
}

class CoachAthleteDayPreview extends StatelessWidget {
  const CoachAthleteDayPreview({
    required this.day,
    required this.workouts,
    required this.onWorkoutTap,
    super.key,
    this.athleteNames,
  });

  final DateTime day;
  final List<SwimflowWorkout> workouts;
  final void Function(SwimflowWorkout workout) onWorkoutTap;
  final Map<String, String>? athleteNames;

  @override
  Widget build(BuildContext context) {
    return CoachSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CoachColors.secondaryContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.pool_rounded, color: CoachColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, d MMMM', 'ru').format(day),
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      workouts.isEmpty
                          ? 'Нет тренировок'
                          : '${workouts.length} ${_workoutsWordRu(workouts.length)}',
                      style: GoogleFonts.inter(fontSize: 13, color: CoachColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (workouts.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...workouts.map(
              (w) {
                final uid = w.athleteUid ?? '';
                final athleteName = athleteNames?[uid]?.trim();
                return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: CoachColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () => onWorkoutTap(w),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (athleteName != null && athleteName.isNotEmpty) ...[
                            Text(
                              athleteName,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: CoachColors.onBackground,
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  w.title,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm', 'ru').format(w.scheduledAt),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: CoachColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _previewMetric(
                                  'Дистанция',
                                  '${w.distanceMeters.toStringAsFixed(0)} м',
                                ),
                              ),
                              Expanded(
                                child: _previewMetric(
                                  'Время',
                                  formatMonthHoursRu(w.durationSeconds),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
              },
            ),
          ],
        ],
      ),
    );
  }

  static String _workoutsWordRu(int n) {
    final m10 = n % 10;
    final m100 = n % 100;
    if (m100 >= 11 && m100 <= 14) return 'тренировок';
    if (m10 == 1) return 'тренировка';
    if (m10 >= 2 && m10 <= 4) return 'тренировки';
    return 'тренировок';
  }

  Widget _previewMetric(String cap, String val) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: CoachColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            cap.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10, color: CoachColors.onSurfaceVariant),
          ),
          Text(
            val,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: CoachColors.primary),
          ),
        ],
      ),
    );
  }
}

class CoachAthleteCompetitionsPanel extends ConsumerWidget {
  const CoachAthleteCompetitionsPanel({required this.athleteId, super.key});

  final String athleteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swims = ref.watch(coachAthleteCompetitionSwimsFamily(athleteId));

    return swims.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (list) => SwimflowRefreshableScroll(
        color: CoachColors.primaryContainer,
        onRefresh: () => refreshCoachAthleteDetail(ref, athleteId),
        child: CompetitionSwimsPanel(
          swims: list,
          readOnly: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        ),
      ),
    );
  }
}

