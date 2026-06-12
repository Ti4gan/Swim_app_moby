import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/coach_exercise_catalog.dart';
import '../data/firestore_messages.dart';
import '../models/coach_template_type.dart';
import '../models/swimflow_intensity.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import 'coach_create_template_sheet.dart';
import 'stitch_widgets.dart';

Future<CoachCatalogExercise?> showCoachTemplateCatalog(BuildContext context) {
  return Navigator.of(context).push<CoachCatalogExercise>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const CoachTemplateCatalogScreen(),
    ),
  );
}

class CoachTemplateCatalogScreen extends ConsumerStatefulWidget {
  const CoachTemplateCatalogScreen({super.key});

  @override
  ConsumerState<CoachTemplateCatalogScreen> createState() => _CoachTemplateCatalogScreenState();
}

class _CoachTemplateCatalogScreenState extends ConsumerState<CoachTemplateCatalogScreen> {
  final _search = TextEditingController();
  String _query = '';
  String? _typeFilter;
  bool _onlyMine = false;
  CoachTemplateCatalogSort _sort = CoachTemplateCatalogSort.type;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<CoachCatalogExercise> _filterAndSort(List<CoachCatalogExercise> all) {
    var list = all.where((e) {
      if (_onlyMine && !e.isCustom) return false;
      if (_typeFilter != null && e.templateType != _typeFilter) return false;
      if (_query.isNotEmpty) {
        final q = _query.toLowerCase();
        final hay = '${e.title} ${e.hint} ${CoachTemplateType.labelRu(e.templateType)}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case CoachTemplateCatalogSort.nameAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case CoachTemplateCatalogSort.metersAsc:
        list.sort((a, b) => a.volumeMeters.compareTo(b.volumeMeters));
      case CoachTemplateCatalogSort.metersDesc:
        list.sort((a, b) => b.volumeMeters.compareTo(a.volumeMeters));
      case CoachTemplateCatalogSort.type:
        list.sort((a, b) {
          final ti = CoachTemplateType.ordered.indexOf(a.templateType);
          final tj = CoachTemplateType.ordered.indexOf(b.templateType);
          if (ti != tj) return ti.compareTo(tj);
          return a.sortOrder.compareTo(b.sortOrder);
        });
    }
    return list;
  }

  Future<void> _confirmDelete(CoachCatalogExercise e) async {
    final repo = ref.read(coachTemplatesRepositoryProvider);
    if (repo == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить шаблон?'),
        content: Text('«${e.title}» будет удалён из вашего каталога.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: StitchColors.error)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await repo.deleteCustomWorkoutTemplate(e.id);
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(swimFirestoreMessageRu(err, saving: true))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(coachAllTemplatesProvider);
    final topPad = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: StitchPageScaffold(
        bottomInset: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8, topPad + 4, 12, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Каталог шаблонов',
                      style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  PopupMenuButton<CoachTemplateCatalogSort>(
                    initialValue: _sort,
                    onSelected: (v) => setState(() => _sort = v),
                    icon: const Icon(Icons.sort_rounded, color: StitchColors.primary),
                    itemBuilder: (ctx) => [
                      for (final s in CoachTemplateCatalogSort.values)
                        PopupMenuItem(value: s, child: Text(s.labelRu)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: StitchGlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(
                  controller: _search,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Поиск по названию или типу…',
                    border: InputBorder.none,
                    icon: Icon(Icons.search_rounded, color: StitchColors.onSurfaceVariant.withValues(alpha: 0.7)),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _FilterChip(
                    label: 'Все',
                    selected: _typeFilter == null && !_onlyMine,
                    onTap: () => setState(() {
                      _typeFilter = null;
                      _onlyMine = false;
                    }),
                  ),
                  _FilterChip(
                    label: 'Мои',
                    selected: _onlyMine,
                    onTap: () => setState(() {
                      _onlyMine = true;
                      _typeFilter = null;
                    }),
                  ),
                  for (final t in CoachTemplateType.ordered)
                    _FilterChip(
                      label: CoachTemplateType.labelRu(t),
                      selected: !_onlyMine && _typeFilter == t,
                      onTap: () => setState(() {
                        _typeFilter = t;
                        _onlyMine = false;
                      }),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: templatesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: StitchColors.primary)),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(swimFirestoreMessageRu(e, saving: false), textAlign: TextAlign.center),
                  ),
                ),
                data: (all) {
                  final list = _filterAndSort(all);
                  if (list.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _query.isNotEmpty || _typeFilter != null || _onlyMine
                              ? 'Ничего не найдено'
                              : 'Шаблонов пока нет',
                          style: GoogleFonts.inter(color: StitchColors.onSurfaceVariant),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final e = list[index];
                      return _TemplateCard(
                        exercise: e,
                        onTap: () => Navigator.pop(context, e),
                        onDelete: e.isCustom ? () => _confirmDelete(e) : null,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final messenger = ScaffoldMessenger.of(context);
          final created = await showCoachCreateTemplateSheet(context);
          if (created == true) {
            messenger.showSnackBar(const SnackBar(content: Text('Шаблон сохранён')));
          }
        },
        backgroundColor: StitchColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text('Свой шаблон', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: StitchColors.primaryFixed,
        checkmarkColor: StitchColors.primary,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? StitchColors.primary : StitchColors.onSurfaceVariant,
        ),
        side: BorderSide(
          color: selected ? StitchColors.primary.withValues(alpha: 0.35) : StitchColors.outlineVariant,
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.exercise,
    required this.onTap,
    this.onDelete,
  });

  final CoachCatalogExercise exercise;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final typeLabel = CoachTemplateType.labelRu(exercise.templateType);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: StitchGlassCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: stitchAquaGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconForType(exercise.templateType), color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            exercise.title,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (exercise.isCustom)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: StitchColors.primaryFixed,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Мой',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: StitchColors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.intervalLabel} · ${exercise.volumeMeters} м · ${SwimflowIntensity.labelRu(exercise.defaultIntensityTier)}',
                      style: GoogleFonts.inter(fontSize: 13, color: StitchColors.onSurfaceVariant),
                    ),
                    if (exercise.hint.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        exercise.hint,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 12, color: StitchColors.outline),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: StitchColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        typeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: StitchColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, color: StitchColors.error.withValues(alpha: 0.85)),
                )
              else
                Icon(Icons.chevron_right_rounded, color: StitchColors.onSurfaceVariant.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case CoachTemplateType.warmup:
        return Icons.wb_sunny_outlined;
      case CoachTemplateType.technique:
        return Icons.architecture_outlined;
      case CoachTemplateType.aerobic:
        return Icons.favorite_outline_rounded;
      case CoachTemplateType.threshold:
        return Icons.speed_rounded;
      case CoachTemplateType.sprint:
        return Icons.bolt_rounded;
      case CoachTemplateType.im:
        return Icons.dashboard_customize_rounded;
      case CoachTemplateType.cooldown:
        return Icons.ac_unit_rounded;
      default:
        return Icons.pool_rounded;
    }
  }
}
