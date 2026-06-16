import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/firestore_messages.dart';
import '../models/competition_swim.dart';
import '../logic/training_input_limits.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';

int? _parseTimeCentiseconds(String raw) {
  final t = raw.trim();
  final m = RegExp(r'^(\d{1,2}):(\d{2})\.(\d{2})$').firstMatch(t);
  if (m == null) return null;
  final min = int.tryParse(m.group(1)!);
  final sec = int.tryParse(m.group(2)!);
  final cs = int.tryParse(m.group(3)!);
  if (min == null || sec == null || cs == null) return null;
  if (sec >= 60 || cs >= 100) return null;
  return min * 6000 + sec * 100 + cs;
}

class StitchCompetitionSwimFormScreen extends ConsumerStatefulWidget {
  const StitchCompetitionSwimFormScreen({super.key});

  @override
  ConsumerState<StitchCompetitionSwimFormScreen> createState() => _StitchCompetitionSwimFormScreenState();
}

class _StitchCompetitionSwimFormScreenState extends ConsumerState<StitchCompetitionSwimFormScreen> {
  final _cityCtrl = TextEditingController();
  final _competitionCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  String _strokeKey = 'free';
  late int _distanceMeters;
  int _poolMeters = 50;
  DateTime _eventDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _distanceMeters = competitionDistancesMetersByStroke[_strokeKey]!.first;
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _competitionCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  Future<void> _pickDate() async {
    final today = _today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate.isAfter(today) ? today : _eventDate,
      firstDate: DateTime(1990),
      lastDate: today,
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _save() async {
    final repo = ref.read(swimflowRepositoryProvider);
    if (repo == null) return;
    final cs = _parseTimeCentiseconds(_timeCtrl.text);
    final city = _cityCtrl.text.trim();
    if (cs == null || cs <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Время в формате мм:сс.сот, например 00:48.22')),
      );
      return;
    }
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите город')),
      );
      return;
    }
    final eventDay = DateTime(_eventDate.year, _eventDate.month, _eventDate.day);
    if (eventDay.isAfter(_today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дата соревнования не может быть в будущем')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final swim = CompetitionSwim(
        id: '',
        eventDate: eventDay,
        createdAt: DateTime.now(),
        distanceMeters: _distanceMeters,
        strokeKey: _strokeKey,
        timeCentiseconds: cs,
        poolLengthMeters: _poolMeters,
        city: city,
        competitionName: _competitionCtrl.text.trim().isEmpty ? null : _competitionCtrl.text.trim(),
      );
      await repo.addCompetitionSwim(swim);
      if (mounted) context.pop();
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
    final distList = competitionDistancesMetersByStroke[_strokeKey]!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Новый заплыв'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: Text(
              'Сохранить',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: _saving ? StitchColors.outline : StitchColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('Стиль', style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _strokeKey,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: [
              for (final e in competitionStrokeLabelsRu.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _strokeKey = v;
                final list = competitionDistancesMetersByStroke[v]!;
                if (!list.contains(_distanceMeters)) {
                  _distanceMeters = list.first;
                }
              });
            },
          ),
          const SizedBox(height: 20),
          Text('Дистанция', style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in distList)
                ChoiceChip(
                  label: Text('$d м'),
                  selected: _distanceMeters == d,
                  onSelected: (_) => setState(() => _distanceMeters = d),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Время результата', style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          TextField(
            controller: _timeCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [CompetitionTimeTextInputFormatter()],
            style: GoogleFonts.lexend(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            decoration: stitchFieldDecoration(hintText: '00:00.00'),
          ),
          const SizedBox(height: 20),
          Text('Длина бассейна', style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant)),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 25, label: Text('25 м')),
              ButtonSegment(value: 50, label: Text('50 м')),
            ],
            selected: {_poolMeters},
            onSelectionChanged: (s) => setState(() => _poolMeters = s.first),
          ),
          const SizedBox(height: 20),
          Text('Город', style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          TextField(
            controller: _cityCtrl,
            decoration: stitchFieldDecoration(
              hintText: 'Например, Минск',
              prefixIcon: const Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: 20),
          Text('Дата', style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text(DateFormat.yMMMMd('ru').format(_eventDate)),
          ),
          const SizedBox(height: 20),
          Text(
            'Название турнира (опционально)',
            style: GoogleFonts.lexend(fontSize: 12, color: StitchColors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _competitionCtrl,
            decoration: stitchFieldDecoration(hintText: 'Название турнира'),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: StitchColors.primaryContainer,
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Сохранить заплыв'),
          ),
        ],
      ),
    );
  }
}
