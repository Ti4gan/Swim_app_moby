import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../logic/workout_wellbeing.dart';
import '../models/swimflow_workout.dart';
import '../providers/data_refresh.dart';
import '../providers/swimflow_providers.dart';
import '../widgets/swimflow_refresh.dart';
import '../theme/tokens.dart';
import '../widgets/month_summary_bento.dart';
import '../widgets/stitch_app_header.dart';
import '../widgets/stitch_widgets.dart';

class StitchCalendarScreen extends ConsumerStatefulWidget {
  const StitchCalendarScreen({super.key});

  @override
  ConsumerState<StitchCalendarScreen> createState() => _StitchCalendarScreenState();
}

class _StitchCalendarScreenState extends ConsumerState<StitchCalendarScreen> {
  late DateTime _month;
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _month = DateTime(n.year, n.month);
    _selected = n;
  }

  @override
  Widget build(BuildContext context) {
    final workouts = ref.watch(swimflowWorkoutsProvider);

    return Scaffold(
      body: StitchPageScaffold(
        child: Column(
          children: [
            const StitchMainShellHeader(),
            Expanded(
              child: SwimflowRefreshableScroll(
                onRefresh: () => refreshSwimmerWorkouts(ref),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy', 'ru').format(_month),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '4 недели тренировок',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _roundNav(Icons.chevron_left_rounded, () {
                            setState(() {
                              _month = DateTime(_month.year, _month.month - 1);
                            });
                          }),
                          const SizedBox(width: 8),
                          _roundNav(Icons.chevron_right_rounded, () {
                            setState(() {
                              _month = DateTime(_month.year, _month.month + 1);
                            });
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  workouts.when(
                    data: (list) {
                      return Column(
                        children: [
                          StitchSurfaceCard(
                            child: _MonthGrid(
                              month: _month,
                              workouts: list,
                              selected: _selected,
                              onSelect: (d) => setState(() => _selected = d),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _DayPreviewCard(
                            day: _selected ?? DateTime.now(),
                            workouts: _workoutsForDay(list, _selected ?? DateTime.now()),
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('$e'),
                  ),
                ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundNav(IconData ic, VoidCallback onTap) {
    return Material(
      color: StitchColors.surfaceContainer,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(ic, color: StitchColors.primary),
        ),
      ),
    );
  }

  List<SwimflowWorkout> _workoutsForDay(List<SwimflowWorkout> list, DateTime day) {
    final out = <SwimflowWorkout>[];
    for (final w in list) {
      if (w.scheduledAt.year == day.year &&
          w.scheduledAt.month == day.month &&
          w.scheduledAt.day == day.day) {
        out.add(w);
      }
    }
    out.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return out;
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.workouts,
    required this.selected,
    required this.onSelect,
  });

  final DateTime month;
  final List<SwimflowWorkout> workouts;
  final DateTime? selected;
  final ValueChanged<DateTime> onSelect;

  bool _hasWorkout(DateTime d) {
    for (final w in workouts) {
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
            style: GoogleFonts.lexend(fontSize: 12, fontWeight: FontWeight.w600, color: StitchColors.outline),
          ),
        ),
      );
    }

    final prevMonthLast = DateTime(month.year, month.month, 0).day;
    for (var i = 0; i < startPad; i++) {
      final dayNum = prevMonthLast - startPad + i + 1;
      cells.add(_dayCell(context, dayNum, muted: true, onTap: null));
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      final isSel = selected != null &&
          selected!.year == date.year &&
          selected!.month == date.month &&
          selected!.day == date.day;
      final has = _hasWorkout(date);
      final moodWorkout = latestPastWorkoutOnDay(workouts, date);
      cells.add(
        _dayCell(
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
        final gridW = bc.maxWidth;
        final cellW = (gridW - 6 * spacing) / 7;
        const cellH = 58.0;
        final rows = <Widget>[];
        for (var i = 0; i < cells.length; i += 7) {
          final end = i + 7 <= cells.length ? i + 7 : cells.length;
          final chunk = cells.sublist(i, end);
          if (i > 0) {
            rows.add(const SizedBox(height: spacing));
          }
          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                for (var j = 0; j < chunk.length; j++) ...[
                  if (j > 0) const SizedBox(width: spacing),
                  SizedBox(
                    width: cellW,
                    height: cellH,
                    child: chunk[j],
                  ),
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

  Widget _dayCell(
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
          color: selected ? StitchColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: hasDot && !selected
              ? Border.all(color: StitchColors.secondaryContainer.withValues(alpha: 0.5), width: 2)
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: StitchColors.primaryContainer.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '$day',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (muted ? StitchColors.onBackground.withValues(alpha: 0.3) : StitchColors.onBackground),
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
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: StitchColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            if (selected)
              Positioned(
                bottom: 6,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayPreviewCard extends StatelessWidget {
  const _DayPreviewCard({required this.day, required this.workouts});

  final DateTime day;
  final List<SwimflowWorkout> workouts;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBFDBFE).withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: StitchColors.primaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pool_rounded, color: StitchColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM', 'ru').format(day),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          workouts.isEmpty
                              ? 'Нет тренировок'
                              : '${workouts.length} ${_workoutsWordRu(workouts.length)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (workouts.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...workouts.map((w) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: StitchColors.background.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => context.push('/workout/${w.id}'),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        w.title,
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                    ),
                                    WorkoutMoodEmoji(
                                      recordMeta: w.recordMeta,
                                      scheduledAt: w.scheduledAt,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      DateFormat('HH:mm', 'ru').format(w.scheduledAt),
                                      style: GoogleFonts.lexend(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: StitchColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _pvMetric(
                                        'Дистанция',
                                        '${w.distanceMeters.toStringAsFixed(0)} м',
                                      ),
                                    ),
                                    Expanded(
                                      child: _pvMetric('Время', formatMonthHoursRu(w.durationSeconds)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
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

  Widget _pvMetric(String cap, String val) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: StitchColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            cap.toUpperCase(),
            style: GoogleFonts.lexend(fontSize: 10, color: StitchColors.outline),
          ),
          Text(
            val,
            style: GoogleFonts.lexend(fontSize: 18, fontWeight: FontWeight.w600, color: StitchColors.primary),
          ),
        ],
      ),
    );
  }
}
