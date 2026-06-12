import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/training_input_limits.dart';
import '../models/swimflow_intensity.dart';
import '../theme/tokens.dart';
import 'stitch_widgets.dart';

class AddSetResult {
  const AddSetResult({
    required this.reps,
    required this.distanceMeters,
    required this.strokeKey,
    required this.intensityIndex,
  });

  final int reps;
  final int distanceMeters;
  final String strokeKey;
  final int intensityIndex;
}

Future<AddSetResult?> showAddSetModal(BuildContext context, {AddSetResult? initial}) {
  return showModalBottomSheet<AddSetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _AddSetSheet(initial: initial);
    },
  );
}

class _AddSetSheet extends StatefulWidget {
  const _AddSetSheet({this.initial});

  final AddSetResult? initial;

  @override
  State<_AddSetSheet> createState() => _AddSetSheetState();
}

class _AddSetSheetState extends State<_AddSetSheet> {
  late final TextEditingController _reps;
  late final TextEditingController _dist;
  final _repsFocus = FocusNode();
  final _distFocus = FocusNode();
  late String _stroke;
  late int _intensity;

  bool get _editing => widget.initial != null;

  static const _strokes = [
    ('free', 'Вольный стиль', Icons.pool_rounded),
    ('breast', 'Брасс', Icons.water_drop_rounded),
    ('fly', 'Баттерфляй', Icons.bolt_rounded),
    ('back', 'На спине', Icons.flip_to_back_rounded),
    ('im', 'Комплекс', Icons.grid_view_rounded),
  ];

  static final _repsFormatter = PositiveIntTextInputFormatter(maxValue: TrainingInputLimits.maxReps);
  static final _distFormatter =
      PositiveIntTextInputFormatter(maxValue: TrainingInputLimits.maxMetersPerRep);

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _reps = TextEditingController(text: '${i?.reps ?? 8}');
    _dist = TextEditingController(text: '${i?.distanceMeters ?? 100}');
    _stroke = i?.strokeKey ?? 'free';
    _intensity = (i?.intensityIndex ?? 2).clamp(0, 3);
  }

  @override
  void dispose() {
    _reps.dispose();
    _dist.dispose();
    _repsFocus.dispose();
    _distFocus.dispose();
    super.dispose();
  }

  AddSetResult _buildResult() {
    return AddSetResult(
      reps: parseTrainingReps(_reps.text),
      distanceMeters: parseTrainingMetersPerRep(_dist.text),
      strokeKey: _stroke,
      intensityIndex: _intensity,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        color: StitchColors.outline,
                      ),
                      Text(
                        _editing ? 'Редактировать сет' : 'Добавить сет',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, _buildResult()),
                        child: Text(_editing ? 'Готово' : 'Добавить'),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _reps,
                                    focusNode: _repsFocus,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [_repsFormatter],
                                    textInputAction: TextInputAction.next,
                                    onSubmitted: (_) => _distFocus.requestFocus(),
                                    style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: StitchColors.surfaceContainerLow,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                      suffixText: '×',
                                      suffixStyle: Theme.of(context).textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _dist,
                                    focusNode: _distFocus,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [_distFormatter],
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                                    style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.w600),
                                    decoration: InputDecoration(
                                      filled: true,
                                      fillColor: StitchColors.surfaceContainerLow,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 2.4,
                          children: _strokes.map((s) {
                            final sel = _stroke == s.$1;
                            return Material(
                              color: sel ? StitchColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: () => setState(() => _stroke = s.$1),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: sel
                                          ? StitchColors.primary
                                          : StitchColors.outlineVariant.withValues(alpha: 0.35),
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    children: [
                                      Icon(s.$3, size: 20, color: sel ? Colors.white : StitchColors.primary),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          s.$2,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                                            color: sel ? Colors.white : StitchColors.onBackground,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            SwimflowIntensity.labelsRu[_intensity],
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: StitchColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 48,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: StitchColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: LayoutBuilder(
                            builder: (context, c) {
                              final w = (c.maxWidth - 8) / 4;
                              return Stack(
                                children: [
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 200),
                                    left: 4 + _intensity * w,
                                    top: 4,
                                    bottom: 4,
                                    width: w - 4,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.06),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: List.generate(4, (i) {
                                      return Expanded(
                                        child: InkWell(
                                          onTap: () => setState(() => _intensity = i),
                                          borderRadius: BorderRadius.circular(999),
                                          child: Center(
                                            child: Text(
                                              SwimflowIntensity.labelsRu[i].toUpperCase(),
                                              style: GoogleFonts.lexend(
                                                fontSize: 9,
                                                fontWeight: i == _intensity ? FontWeight.w700 : FontWeight.w500,
                                                color: i == _intensity
                                                    ? StitchColors.primary
                                                    : StitchColors.outline,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        StitchAquaButton(
                          label: _editing ? 'Сохранить сет' : 'Добавить в тренировку',
                          onTap: () => Navigator.pop(context, _buildResult()),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: const BorderSide(color: StitchColors.outlineVariant),
                            ),
                            child: const Text('Отмена'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
