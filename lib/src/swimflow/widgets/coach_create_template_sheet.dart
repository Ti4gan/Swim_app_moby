import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/coach_exercise_catalog.dart';
import '../data/firestore_messages.dart';
import '../models/coach_template_type.dart';
import '../models/swimflow_intensity.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import 'stitch_widgets.dart';

Future<bool?> showCoachCreateTemplateSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _CoachCreateTemplateSheet(),
  );
}

class _CoachCreateTemplateSheet extends ConsumerStatefulWidget {
  const _CoachCreateTemplateSheet();

  @override
  ConsumerState<_CoachCreateTemplateSheet> createState() => _CoachCreateTemplateSheetState();
}

class _CoachCreateTemplateSheetState extends ConsumerState<_CoachCreateTemplateSheet> {
  final _title = TextEditingController();
  final _hint = TextEditingController();
  final _reps = TextEditingController(text: '8');
  final _dist = TextEditingController(text: '100');
  String _type = CoachTemplateType.aerobic;
  String _stroke = 'free';
  int _intensity = 1;
  bool _saving = false;
  String? _error;

  static const _strokes = [
    ('free', 'Вольный'),
    ('breast', 'Брасс'),
    ('fly', 'Баттерфляй'),
    ('back', 'На спине'),
    ('im', 'Комплекс'),
  ];

  @override
  void dispose() {
    _title.dispose();
    _hint.dispose();
    _reps.dispose();
    _dist.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(coachTemplatesRepositoryProvider);
    if (repo == null) return;
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Укажите название');
      return;
    }
    final reps = int.tryParse(_reps.text.trim()) ?? 1;
    final dist = int.tryParse(_dist.text.trim()) ?? 0;
    if (dist <= 0) {
      setState(() => _error = 'Дистанция должна быть больше 0');
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      final customCount = ref.read(coachCustomTemplatesProvider).valueOrNull?.length ?? 0;
      await repo.createCustomWorkoutTemplate(
        CoachCatalogExercise(
          id: '',
          title: title,
          hint: _hint.text.trim(),
          presetReps: reps <= 0 ? 1 : reps,
          presetIntervalMeters: dist,
          defaultIntensityTier: _intensity.clamp(0, 3),
          templateType: _type,
          strokeKey: _stroke,
          sortOrder: 1000 + customCount,
          isCustom: true,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = swimFirestoreMessageRu(e, saving: true);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: StitchColors.surfaceContainerLowest,
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: StitchColors.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Новый шаблон',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Название',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Тип',
                    style: GoogleFonts.inter(fontSize: 13, color: StitchColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final t in CoachTemplateType.ordered)
                        FilterChip(
                          label: Text(CoachTemplateType.labelRu(t)),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                          selectedColor: StitchColors.primaryFixed,
                          checkmarkColor: StitchColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Стиль',
                    style: GoogleFonts.inter(fontSize: 13, color: StitchColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in _strokes)
                        FilterChip(
                          label: Text(s.$2),
                          selected: _stroke == s.$1,
                          onSelected: (_) => setState(() => _stroke = s.$1),
                          selectedColor: StitchColors.primaryFixed,
                          checkmarkColor: StitchColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reps,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Повторы',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _dist,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Метры',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Интенсивность',
                    style: GoogleFonts.inter(fontSize: 13, color: StitchColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<int>(
                    segments: [
                      for (var i = 0; i < SwimflowIntensity.labelsRu.length; i++)
                        ButtonSegment(value: i, label: Text(SwimflowIntensity.labelsRu[i])),
                    ],
                    selected: {_intensity},
                    onSelectionChanged: (s) => setState(() => _intensity = s.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _hint,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Подсказка (необязательно)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: StitchColors.error)),
                  ],
                  const SizedBox(height: 20),
                  StitchAquaButton(
                    label: _saving ? 'Сохранение…' : 'Сохранить шаблон',
                    icon: Icons.check_rounded,
                    onTap: _saving ? null : _save,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
