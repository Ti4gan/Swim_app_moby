import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/competition_swim.dart';
import '../theme/tokens.dart';
import 'stitch_widgets.dart';

class AppliedSwimFilters {
  const AppliedSwimFilters({
    this.dateFrom,
    this.dateTo,
    this.cityNormalized,
    this.poolLengthMeters,
    required this.strokeKey,
    required this.distanceMeters,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? cityNormalized;
  final int? poolLengthMeters;
  final String strokeKey;
  final int distanceMeters;

  bool get showsBestResultCard => poolLengthMeters != null;

  bool matches(CompetitionSwim s) {
    if (dateFrom != null && dateTo != null) {
      var from = DateTime(dateFrom!.year, dateFrom!.month, dateFrom!.day);
      var to = DateTime(dateTo!.year, dateTo!.month, dateTo!.day);
      if (from.isAfter(to)) {
        final t = from;
        from = to;
        to = t;
      }
      final d = DateTime(s.eventDate.year, s.eventDate.month, s.eventDate.day);
      if (d.isBefore(from) || d.isAfter(to)) return false;
    }
    if (cityNormalized != null && cityNormalized!.isNotEmpty) {
      if (s.city.trim().toLowerCase() != cityNormalized) return false;
    }
    if (poolLengthMeters != null) {
      if (s.poolLengthMeters != poolLengthMeters) return false;
    }
    if (s.strokeKey != strokeKey) return false;
    if (s.distanceMeters != distanceMeters) return false;
    return true;
  }
}

String formatCompetitionTimeCs(int cs) {
  final totalSec = cs ~/ 100;
  final c = cs % 100;
  final m = totalSec ~/ 60;
  final s = totalSec % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${c.toString().padLeft(2, '0')}';
}

String poolCourseRu(int meters) => '$meters м';

String competitionStrokeRu(String k) => competitionStrokeLabelsRu[k] ?? k;

class CompetitionSwimsPanel extends StatefulWidget {
  const CompetitionSwimsPanel({
    required this.swims,
    super.key,
    this.readOnly = false,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.showHeader = true,
  });

  final List<CompetitionSwim> swims;
  final bool readOnly;
  final EdgeInsets padding;
  final bool showHeader;

  @override
  State<CompetitionSwimsPanel> createState() => _CompetitionSwimsPanelState();
}

class _CompetitionSwimsPanelState extends State<CompetitionSwimsPanel> {
  final _cityFilterCtrl = TextEditingController();
  DateTime? _fFrom;
  DateTime? _fTo;
  int? _fPool;
  String _fStroke = 'free';
  int _fDistance = 100;
  AppliedSwimFilters? _applied;
  bool _filtersOpen = false;

  @override
  void dispose() {
    _cityFilterCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fFrom ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) setState(() => _fFrom = picked);
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fTo ?? _fFrom ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) setState(() => _fTo = picked);
  }

  void _applyFilters() {
    DateTime? from;
    DateTime? to;
    if (_fFrom != null && _fTo != null) {
      from = DateTime(_fFrom!.year, _fFrom!.month, _fFrom!.day);
      to = DateTime(_fTo!.year, _fTo!.month, _fTo!.day);
      if (from.isAfter(to)) {
        final t = from;
        from = to;
        to = t;
      }
    }
    final city = _cityFilterCtrl.text.trim();
    setState(() {
      _applied = AppliedSwimFilters(
        dateFrom: from,
        dateTo: to,
        cityNormalized: city.isEmpty ? null : city.toLowerCase(),
        poolLengthMeters: _fPool,
        strokeKey: _fStroke,
        distanceMeters: _fDistance,
      );
    });
  }

  void _resetFilters() {
    setState(() {
      _applied = null;
      _fFrom = null;
      _fTo = null;
      _fPool = null;
      _fStroke = 'free';
      _fDistance = 100;
      _cityFilterCtrl.clear();
    });
  }

  List<CompetitionSwim> _visible() {
    if (_applied == null) return widget.swims;
    return widget.swims.where(_applied!.matches).toList();
  }

  CompetitionSwim? _bestInSelection(List<CompetitionSwim> visible) {
    if (_applied == null || !_applied!.showsBestResultCard) return null;
    final cand = visible.where((s) => s.timeCentiseconds > 0).toList();
    if (cand.isEmpty) return null;
    cand.sort((a, b) => a.timeCentiseconds.compareTo(b.timeCentiseconds));
    return cand.first;
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible();
    final best = _bestInSelection(visible);
    final emptyAll = widget.swims.isEmpty;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: widget.padding,
      children: [
        if (widget.showHeader) ...[
          Text(
            widget.readOnly ? 'Результаты пловца' : 'Заплывы на соревнованиях',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton.icon(
          onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
          icon: Icon(_filtersOpen ? Icons.expand_less_rounded : Icons.tune_rounded),
          label: Text(_filtersOpen ? 'Скрыть фильтры' : 'Фильтры'),
        ),
        if (_filtersOpen) ...[
          const SizedBox(height: 12),
          StitchGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFrom,
                    icon: const Icon(Icons.date_range_outlined, size: 18),
                    label: Text(_fFrom == null ? 'Дата с' : DateFormat.yMd('ru').format(_fFrom!)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickTo,
                    icon: const Icon(Icons.date_range_outlined, size: 18),
                    label: Text(_fTo == null ? 'Дата по' : DateFormat.yMd('ru').format(_fTo!)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Стиль', style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in competitionStrokeLabelsRu.entries)
                    ChoiceChip(
                      label: Text(e.value, style: const TextStyle(fontSize: 12)),
                      selected: _fStroke == e.key,
                      onSelected: (sel) {
                        if (!sel) return;
                        setState(() {
                          _fStroke = e.key;
                          final list = competitionDistancesMetersByStroke[e.key]!;
                          if (!list.contains(_fDistance)) {
                            _fDistance = list.first;
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Дистанция', style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in competitionDistancesMetersByStroke[_fStroke]!)
                    ChoiceChip(
                      label: Text('$d м'),
                      selected: _fDistance == d,
                      onSelected: (_) => setState(() => _fDistance = d),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Длина бассейна', style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 25, label: Text('25 м')),
                  ButtonSegment(value: 50, label: Text('50 м')),
                ],
                emptySelectionAllowed: true,
                selected: _fPool == null ? {} : {_fPool!},
                onSelectionChanged: (s) => setState(() => _fPool = s.isEmpty ? null : s.first),
              ),
              const SizedBox(height: 12),
                TextField(
                  controller: _cityFilterCtrl,
                  onChanged: (_) => setState(() {}),
                  decoration: stitchFieldDecoration(
                    labelText: 'Город',
                    hintText: 'Например, Минск',
                    prefixIcon: const Icon(Icons.place_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _applyFilters,
                        child: const Text('Применить'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(onPressed: _resetFilters, child: const Text('Сбросить')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (best != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  StitchColors.primaryFixed.withValues(alpha: 0.85),
                  StitchColors.primaryFixedDim.withValues(alpha: 0.5),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: StitchColors.primary.withValues(alpha: 0.12)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'РЕКОРД В ВЫБОРКЕ',
                        style: GoogleFonts.lexend(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: StitchColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Лучший результат', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        '${best.distanceMeters} м · ${competitionStrokeRu(best.strokeKey)}',
                        style: GoogleFonts.lexend(fontSize: 14, color: StitchColors.onPrimaryFixedVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCompetitionTimeCs(best.timeCentiseconds),
                        style: GoogleFonts.lexend(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: StitchColors.onPrimaryFixedVariant,
                        ),
                      ),
                      if (best.competitionName != null && best.competitionName!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(best.competitionName!, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.emoji_events_rounded, color: StitchColors.secondary, size: 36),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else if (_applied != null && visible.isEmpty) ...[
          StitchGlassCard(
            child: Text(
              'В текущей выборке нет заплывов. Измените фильтры.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (visible.isEmpty && _applied == null && emptyAll)
          StitchGlassCard(
            child: Text(
              widget.readOnly
                  ? 'Пловец ещё не добавил результаты соревнований.'
                  : 'Пока нет записей. Нажмите «+», чтобы добавить заплыв.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          ..._yearSections(context, visible),
      ],
    );
  }

  List<Widget> _yearSections(BuildContext context, List<CompetitionSwim> visible) {
    if (visible.isEmpty) return [];
    final map = <int, List<CompetitionSwim>>{};
    for (final s in visible) {
      map.putIfAbsent(s.eventDate.year, () => []).add(s);
    }
    for (final e in map.values) {
      e.sort((a, b) => b.eventDate.compareTo(a.eventDate));
    }
    final years = map.keys.toList()..sort((a, b) => b.compareTo(a));
    final out = <Widget>[];
    for (final y in years) {
      out.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Text(
            '$y',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: StitchColors.primary,
            ),
          ),
        ),
      );
      for (final s in map[y]!) {
        out.add(Padding(padding: const EdgeInsets.only(bottom: 12), child: CompetitionSwimCard(swim: s)));
      }
    }
    return out;
  }
}

class CompetitionSwimCard extends StatelessWidget {
  const CompetitionSwimCard({required this.swim, super.key});

  final CompetitionSwim swim;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: StitchColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: StitchColors.primary.withValues(alpha: 0.08)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${swim.distanceMeters} м', style: Theme.of(context).textTheme.titleMedium),
                      Text(competitionStrokeRu(swim.strokeKey), style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(
                  formatCompetitionTimeCs(swim.timeCentiseconds),
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: StitchColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _mini(Icons.place_outlined, swim.city),
                _mini(Icons.straighten_outlined, poolCourseRu(swim.poolLengthMeters)),
                _mini(Icons.calendar_today_outlined, DateFormat.yMMMMd('ru').format(swim.eventDate)),
                if (swim.competitionName != null && swim.competitionName!.isNotEmpty)
                  _mini(Icons.emoji_events_outlined, swim.competitionName!),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(IconData ic, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(ic, size: 16, color: StitchColors.outline),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
