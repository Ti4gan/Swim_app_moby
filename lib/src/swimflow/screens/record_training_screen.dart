import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/firestore_messages.dart';
import '../logic/training_input_limits.dart';
import '../logic/workout_date_label.dart';
import '../models/linked_athlete.dart';
import '../models/swimflow_intensity.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import '../widgets/add_set_modal.dart';
import '../widgets/coach_template_catalog_screen.dart';
import '../widgets/stitch_app_header.dart';
import '../widgets/stitch_widgets.dart';

class _SetLine {
  _SetLine({
    required this.id,
    required this.reps,
    required this.distanceMeters,
    required this.strokeKey,
    required this.intensityIndex,
    this.subtitleOverride,
  });

  final int id;
  final int reps;
  final int distanceMeters;
  final String strokeKey;
  final int intensityIndex;
  final String? subtitleOverride;

  static const _strokeNamesRu = {
    'free': 'Вольный стиль',
    'breast': 'Брасс',
    'fly': 'Баттерфляй',
    'back': 'На спине',
    'im': 'Комплекс',
  };

  int get meters => reps * distanceMeters;

  String get title => reps > 1 ? '$reps × $distanceMeters м' : '$distanceMeters м';

  String get subtitle => subtitleOverride ?? _strokeNamesRu[strokeKey] ?? '';
}

class StitchRecordTrainingScreen extends ConsumerStatefulWidget {
  const StitchRecordTrainingScreen({
    super.key,
    this.initialAthleteUid,
    this.initialScheduledDate,
  });

  final String? initialAthleteUid;
  final DateTime? initialScheduledDate;

  @override
  ConsumerState<StitchRecordTrainingScreen> createState() => _StitchRecordTrainingScreenState();
}

class _StitchRecordTrainingScreenState extends ConsumerState<StitchRecordTrainingScreen> {
  final Set<String> _targetAthleteUids = {};
  late DateTime _scheduledDate = _dateOnly(DateTime.now());
  final List<_SetLine> _sets = [];
  final TextEditingController _minCtrl = TextEditingController(text: '45');
  int _nextSetId = 0;
  bool _saving = false;

  static final _minutesFormatter =
      PositiveIntTextInputFormatter(maxValue: TrainingInputLimits.maxWorkoutMinutes);

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static const _strokeShortRu = {
    'free': 'Кроль',
    'breast': 'Брасс',
    'fly': 'Баттер',
    'back': 'Спина',
    'im': 'Комплекс',
  };

  @override
  void initState() {
    super.initState();
    final preset = widget.initialAthleteUid;
    if (preset != null && preset.isNotEmpty) {
      _targetAthleteUids.add(preset);
    }
    final d = widget.initialScheduledDate;
    if (d != null) {
      _scheduledDate = _dateOnly(d);
    }
  }

  int get _totalMeters => _sets.fold(0, (a, s) => a + s.meters);

  int get _durationSecondsTotal {
    final m = clampTrainingWorkoutMinutes(int.tryParse(_minCtrl.text.trim()) ?? 0);
    return m * 60;
  }

  double get _avgIntensityIndex {
    if (_sets.isEmpty) return 0;
    var sum = 0;
    for (final s in _sets) {
      sum += s.intensityIndex.clamp(0, 3);
    }
    return sum / _sets.length;
  }

  int get _intensityScore10 {
    if (_sets.isEmpty) return 0;
    return ((_avgIntensityIndex / 3) * 9 + 1).round().clamp(1, 10);
  }

  String get _intensityShortLabel {
    if (_sets.isEmpty) return '—';
    final i = _avgIntensityIndex.round().clamp(0, 3);
    return const ['Низ', 'Ср', 'Выс', 'MAX'][i];
  }

  Set<String> get _strokeKeys => _sets.map((s) => s.strokeKey).toSet();

  String get _styleLabel {
    if (_sets.isEmpty) return '—';
    if (_strokeKeys.length >= 2) return 'MIX';
    return _strokeShortRu[_strokeKeys.first] ?? '—';
  }

  String get _styleDetail {
    if (_sets.isEmpty) return '';
    if (_strokeKeys.length >= 2) return '${_strokeKeys.length}';
    return '';
  }

  List<Map<String, dynamic>> get _setsPayload => _sets
      .map((s) => {
            'title': s.title,
            'subtitle': s.subtitle,
            'meters': s.meters,
            'strokeKey': s.strokeKey,
            'intensityIndex': s.intensityIndex,
            'intensityLabel': SwimflowIntensity.labelRu(s.intensityIndex),
          })
      .toList();

  @override
  void dispose() {
    _minCtrl.dispose();
    super.dispose();
  }

  _SetLine _lineFromResult(AddSetResult r, {int? id, String? subtitleOverride}) {
    final reps = parseTrainingReps('${r.reps}');
    final dist = parseTrainingMetersPerRep('${r.distanceMeters}');
    return _SetLine(
      id: id ?? ++_nextSetId,
      reps: reps,
      distanceMeters: dist,
      strokeKey: r.strokeKey,
      intensityIndex: r.intensityIndex.clamp(0, 3),
      subtitleOverride: subtitleOverride,
    );
  }

  AddSetResult _resultFromLine(_SetLine s) {
    return AddSetResult(
      reps: s.reps,
      distanceMeters: s.distanceMeters,
      strokeKey: s.strokeKey,
      intensityIndex: s.intensityIndex,
    );
  }

  Future<void> _openTemplateCatalog() async {
    final e = await showCoachTemplateCatalog(context);
    if (e == null || !mounted) return;
    final interval = e.toInterval();
    final meters = interval.volumeMeters > 0 ? interval.volumeMeters : e.volumeMeters;
    setState(() {
      _sets.add(
        _lineFromResult(
          AddSetResult(
            reps: e.presetReps <= 0 ? 1 : e.presetReps,
            distanceMeters: e.presetIntervalMeters <= 0 ? meters : e.presetIntervalMeters,
            strokeKey: e.strokeKey,
            intensityIndex: e.defaultIntensityTier,
          ),
          subtitleOverride: e.title,
        ),
      );
    });
  }

  Future<void> _addSet() async {
    final r = await showAddSetModal(context);
    if (r == null || !mounted) return;
    setState(() => _sets.add(_lineFromResult(r)));
  }

  Future<void> _editSet(int index) async {
    final r = await showAddSetModal(context, initial: _resultFromLine(_sets[index]));
    if (r == null || !mounted) return;
    setState(() => _sets[index] = _lineFromResult(r, id: _sets[index].id));
  }

  void _reorderSet(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _sets.removeAt(oldIndex);
      _sets.insert(newIndex, item);
    });
  }

  void _removeSet(int index) {
    setState(() => _sets.removeAt(index));
  }

  Widget _setCard(_SetLine s, int index) {
    return Padding(
      key: ValueKey(s.id),
      padding: const EdgeInsets.only(bottom: 12),
      child: StitchGlassCard(
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.drag_handle_rounded, color: StitchColors.outline),
              ),
            ),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _editSet(index),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
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
                              Text(s.title, style: Theme.of(context).textTheme.titleMedium),
                              Text(
                                '${s.subtitle} · ${SwimflowIntensity.labelRu(s.intensityIndex)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: StitchColors.outline,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${s.meters}',
                              style: GoogleFonts.lexend(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: StitchColors.primary,
                              ),
                            ),
                            Text(
                              'МЕТРОВ',
                              style: GoogleFonts.lexend(fontSize: 10, color: StitchColors.outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => _removeSet(index),
              icon: const Icon(Icons.delete_outline_rounded),
              color: StitchColors.error,
              tooltip: 'Удалить сет',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickScheduledDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) setState(() => _scheduledDate = _dateOnly(picked));
  }

  Future<void> _save() async {
    if (_targetAthleteUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите хотя бы одного пловца')),
      );
      return;
    }
    if (_sets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Добавьте хотя бы один сет')),
      );
      return;
    }
    if (_totalMeters <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дистанция должна быть больше 0 м')),
      );
      return;
    }
    if (_totalMeters > TrainingInputLimits.maxTotalMetersPerWorkout) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Максимум ${TrainingInputLimits.maxTotalMetersPerWorkout} м за тренировку'),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(coachRepositoryProvider);
      if (repo == null) return;
      final scheduledAt = combineWorkoutScheduleDate(_scheduledDate);
      var ok = 0;
      for (final uid in _targetAthleteUids) {
        await repo.logAthleteWorkout(
          athleteUid: uid,
          title: '',
          totalMeters: _totalMeters.toDouble(),
          durationSecondsTotal: _durationSecondsTotal,
          scheduledAt: scheduledAt,
          sets: _setsPayload,
        );
        ok++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Тренировка записана: $ok пловцов')),
        );
        context.pop();
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

  Widget _metricCard({
    required IconData icon,
    required String label,
    required Widget valueChild,
    String? detail,
  }) {
    return StitchGlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: StitchColors.secondary),
          const SizedBox(height: 8),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: StitchColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          valueChild,
          if (detail != null && detail.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              detail,
              style: GoogleFonts.inter(fontSize: 13, color: StitchColors.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.straighten_rounded,
                label: 'Дистанция',
                valueChild: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$_totalMeters',
                      style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'м',
                      style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                icon: Icons.schedule_rounded,
                label: 'Время',
                valueChild: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(
                      width: 52,
                      child: TextField(
                        controller: _minCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [_minutesFormatter],
                        style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Text(
                      'мин',
                      style: GoogleFonts.inter(fontSize: 14, color: StitchColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                icon: Icons.bolt_rounded,
                label: 'Интенсивность',
                valueChild: Text(
                  _intensityShortLabel,
                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                detail: _sets.isEmpty ? null : '$_intensityScore10/10',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricCard(
                icon: Icons.water_drop_outlined,
                label: 'Стиль',
                valueChild: Text(
                  _styleLabel,
                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                detail: _styleDetail.isEmpty ? null : _styleDetail,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final athletes = ref.watch(coachAthletesProvider);

    return Scaffold(
      body: StitchPageScaffold(
        bottomInset: safeBottom + 16,
        child: Column(
          children: [
            const StitchSubpageHeader(),
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(20, 8, 20, 28 + safeBottom),
                children: [
                  Text(
                    'Запись тренировки',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  StitchGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Дата тренировки',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: StitchColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: _pickScheduledDate,
                          icon: const Icon(Icons.calendar_month_rounded, color: StitchColors.primary),
                          label: Text(
                            DateFormat('EEEE, d MMMM yyyy', 'ru').format(_scheduledDate),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: StitchColors.onBackground,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _metricsGrid(),
                  const SizedBox(height: 24),
                  Text('Ваша тренировка', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: _openTemplateCatalog,
                        icon: const Icon(Icons.library_books_outlined, size: 18, color: StitchColors.primary),
                        label: Text(
                          'Каталог шаблонов',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: StitchColors.primary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addSet,
                        icon: const Icon(Icons.add_rounded, size: 18, color: StitchColors.primary),
                        label: Text(
                          'Добавить сет',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: StitchColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_sets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'Добавьте сеты или выберите шаблон.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: StitchColors.onSurfaceVariant,
                            ),
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: _sets.length,
                      onReorder: _reorderSet,
                      itemBuilder: (context, index) => _setCard(_sets[index], index),
                    ),
                  const SizedBox(height: 24),
                  athletes.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) {
                      if (list.isEmpty) {
                        return StitchGlassCard(
                          child: Text(
                            'Нет привязанных пловцов',
                            style: GoogleFonts.inter(color: StitchColors.onSurfaceVariant),
                          ),
                        );
                      }
                      return StitchGlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Пловцы',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _targetAthleteUids
                                      ..clear()
                                      ..addAll(list.map((a) => a.uid));
                                  }),
                                  child: const Text('Все'),
                                ),
                                TextButton(
                                  onPressed: () => setState(_targetAthleteUids.clear),
                                  child: const Text('Сброс'),
                                ),
                              ],
                            ),
                            Text(
                              'Выбрано: ${_targetAthleteUids.length}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: StitchColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final LinkedAthlete a in list)
                                  FilterChip(
                                    label: Text(a.displayName.isEmpty ? a.uid : a.displayName),
                                    selected: _targetAthleteUids.contains(a.uid),
                                    onSelected: (sel) => setState(() {
                                      if (sel) {
                                        _targetAthleteUids.add(a.uid);
                                      } else {
                                        _targetAthleteUids.remove(a.uid);
                                      }
                                    }),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  StitchAquaButton(
                    label: _saving ? 'Сохранение…' : 'Сохранить тренировку',
                    icon: Icons.check_circle_outline_rounded,
                    onTap: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
