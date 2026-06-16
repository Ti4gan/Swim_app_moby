import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/coach_notification.dart';
import '../../models/linked_athlete.dart';
import '../../providers/coach_notifications_providers.dart';
import '../../providers/swimflow_providers.dart';
import '../../theme/coach_theme.dart';
import '../../widgets/coach_widgets.dart';

class CoachNotificationsScreen extends ConsumerStatefulWidget {
  const CoachNotificationsScreen({super.key});

  @override
  ConsumerState<CoachNotificationsScreen> createState() => _CoachNotificationsScreenState();
}

class _CoachNotificationsScreenState extends ConsumerState<CoachNotificationsScreen> {
  int _typeFilter = 0;
  String? _athleteFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markAllSeen();
    });
  }

  void _markAllSeen() {
    final items = ref.read(coachNotificationsProvider);
    ref.read(seenCoachNotificationIdsProvider.notifier).markAllSeen(
          items.map((n) => n.id),
        );
  }

  List<CoachNotification> _filter(List<CoachNotification> items) {
    var result = items;
    if (_typeFilter == 1) {
      result = result.where((n) => n.type == CoachNotificationType.wellbeing).toList();
    } else if (_typeFilter == 2) {
      result = result.where((n) => n.type == CoachNotificationType.competition).toList();
    }
    if (_athleteFilter != null) {
      result = result.where((n) => n.athleteUid == _athleteFilter).toList();
    }
    return result;
  }

  void _openNotification(CoachNotification n) {
    ref.read(seenCoachNotificationIdsProvider.notifier).markSeen(n.id);
    switch (n.type) {
      case CoachNotificationType.wellbeing:
        if (n.workoutId != null && n.workoutId!.isNotEmpty) {
          context.push('/workout/${n.workoutId}?athleteId=${n.athleteUid}');
        }
      case CoachNotificationType.competition:
        context.push('/coach/swimmers/${n.athleteUid}?tab=2');
    }
  }

  IconData _iconFor(CoachNotificationType type) {
    return switch (type) {
      CoachNotificationType.wellbeing => Icons.sentiment_satisfied_alt_rounded,
      CoachNotificationType.competition => Icons.emoji_events_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(coachNotificationsProvider);
    final seen = ref.watch(seenCoachNotificationIdsProvider);
    final athletes = ref.watch(coachAthletesProvider).valueOrNull ?? [];
    final filtered = _filter(items);

    return Theme(
      data: CoachAppTheme.light,
      child: Scaffold(
        backgroundColor: CoachColors.background,
        body: CoachPageBackground(
          bottomInset: 32,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CoachSubpageHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  'Уведомления',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: CoachColors.onBackground,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _FilterChip(
                      label: 'Все',
                      selected: _typeFilter == 0,
                      onTap: () => setState(() => _typeFilter = 0),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Настроение',
                      selected: _typeFilter == 1,
                      onTap: () => setState(() => _typeFilter = 1),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Соревнования',
                      selected: _typeFilter == 2,
                      onTap: () => setState(() => _typeFilter = 2),
                    ),
                    if (athletes.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _AthleteFilter(
                        athletes: athletes,
                        value: _athleteFilter,
                        onChanged: (v) => setState(() => _athleteFilter = v),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (_typeFilter != 0 || _athleteFilter != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '${filtered.length} из ${items.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: CoachColors.onSurfaceVariant,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'Пока нет уведомлений',
                            style: GoogleFonts.inter(color: CoachColors.onSurfaceVariant),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final n = filtered[i];
                          final unread = !seen.contains(n.id);
                          return Material(
                            color: CoachColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(14),
                            child: InkWell(
                              onTap: () => _openNotification(n),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: unread
                                        ? CoachColors.primaryContainer.withValues(alpha: 0.25)
                                        : CoachColors.outlineVariant.withValues(alpha: 0.35),
                                  ),
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: CoachColors.secondaryContainer.withValues(alpha: 0.25),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(_iconFor(n.type), color: CoachColors.primaryContainer),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            n.title,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: CoachColors.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            n.detail,
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: CoachColors.onBackground,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            n.subtitle,
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: CoachColors.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (unread)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        margin: const EdgeInsets.only(top: 4),
                                        decoration: const BoxDecoration(
                                          color: CoachColors.primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? CoachColors.primaryContainer : CoachColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? CoachColors.primaryContainer
                : CoachColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : CoachColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _AthleteFilter extends StatelessWidget {
  const _AthleteFilter({
    required this.athletes,
    required this.value,
    required this.onChanged,
  });

  final List<LinkedAthlete> athletes;
  final String? value;
  final ValueChanged<String?> onChanged;

  String _label() {
    if (value == null) return 'Пловец';
    final a = athletes.where((a) => a.uid == value).firstOrNull;
    return a?.displayName.isNotEmpty == true ? a!.displayName : 'Пловец';
  }

  @override
  Widget build(BuildContext context) {
    final label = _label();
    final selected = value != null;
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        backgroundColor: CoachColors.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 36, height: 4, decoration: BoxDecoration(color: CoachColors.outlineVariant, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Выберите пловца', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: CoachColors.onBackground)),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text('Все пловцы', style: GoogleFonts.inter(fontSize: 14, color: value == null ? CoachColors.primaryContainer : CoachColors.onBackground)),
                trailing: value == null ? const Icon(Icons.check, color: CoachColors.primaryContainer) : null,
                onTap: () { Navigator.pop(ctx); onChanged(null); },
              ),
              ...athletes.map((a) => ListTile(
                title: Text(a.displayName.isNotEmpty ? a.displayName : 'Пловец', style: GoogleFonts.inter(fontSize: 14, color: value == a.uid ? CoachColors.primaryContainer : CoachColors.onBackground)),
                trailing: value == a.uid ? const Icon(Icons.check, color: CoachColors.primaryContainer) : null,
                onTap: () { Navigator.pop(ctx); onChanged(a.uid); },
              )),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        height: 36,
        decoration: BoxDecoration(
          color: selected ? CoachColors.primaryContainer : CoachColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? CoachColors.primaryContainer
                : CoachColors.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : CoachColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down_rounded, size: 18, color: selected ? Colors.white : CoachColors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
