import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/linked_athlete.dart';
import '../../models/swimflow_sport_rank.dart';
import '../../models/swimflow_workout.dart';
import '../../models/swimmer_training_group.dart';
import '../../providers/data_refresh.dart';
import '../../providers/swimflow_providers.dart';
import '../../widgets/swimflow_refresh.dart';
import '../../theme/coach_theme.dart';
import '../../widgets/coach_widgets.dart';
import '../../widgets/profile_avatar.dart';
import 'coach_invite_sheet.dart';

Future<T?> _showCoachPickerSheet<T>(
  BuildContext context, {
  String? title,
  required List<Widget> children,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        minChildSize: 0.28,
        maxChildSize: 0.88,
        builder: (_, scrollController) {
          return Material(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CoachColors.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                    child: Text(
                      title,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ...children,
              ],
            ),
          );
        },
      );
    },
  );
}

class CoachAthletesScreen extends ConsumerStatefulWidget {
  const CoachAthletesScreen({super.key});

  static Future<void> showInviteSheet(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Theme(
        data: CoachAppTheme.light,
        child: const CoachInviteSheet(),
      ),
    );
  }

  @override
  ConsumerState<CoachAthletesScreen> createState() => _CoachAthletesScreenState();
}

class _CoachAthletesScreenState extends ConsumerState<CoachAthletesScreen> {
  final _searchCtrl = TextEditingController();
  String? _groupFilter;
  String? _rankFilter;
  bool _filtersOpen = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Map<String, DateTime> _lastActivityByUid(List<SwimflowWorkout> team) {
    final map = <String, DateTime>{};
    for (final w in team) {
      final uid = w.athleteUid;
      if (uid == null || uid.isEmpty) continue;
      final prev = map[uid];
      if (prev == null || w.scheduledAt.isAfter(prev)) {
        map[uid] = w.scheduledAt;
      }
    }
    return map;
  }

  List<LinkedAthlete> _filterList(List<LinkedAthlete> list) {
    final q = _searchCtrl.text.trim().toLowerCase();
    return list.where((a) {
      if (q.isNotEmpty) {
        final hay = '${a.displayName} ${a.city} ${a.coachInviteLabel}'.toLowerCase();
        if (!hay.contains(q)) return false;
      }
      if (_groupFilter != null && a.trainingGroup != _groupFilter) return false;
      if (_rankFilter != null && a.sportRankId != _rankFilter) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
  }

  Future<void> _pickGroup(LinkedAthlete athlete) async {
    final repo = ref.read(coachRepositoryProvider);
    if (repo == null) return;
    final picked = await _showCoachPickerSheet<String>(
      context,
      title: 'Группа',
      children: [
        for (final id in SwimmerTrainingGroup.orderedIds)
          ListTile(
            title: Text(SwimmerTrainingGroup.labelRu(id)),
            trailing: athlete.trainingGroup == id ? const Icon(Icons.check_rounded) : null,
            onTap: () => Navigator.pop(context, id),
          ),
      ],
    );
    if (picked == null || picked == athlete.trainingGroup) return;
    try {
      await repo.updateAthleteTrainingGroup(athlete.uid, picked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final athletes = ref.watch(coachAthletesProvider);
    final teamWorkouts = ref.watch(coachTeamWorkoutsProvider);
    return Scaffold(
      backgroundColor: CoachColors.background,
      body: CoachPageBackground(
        bottomInset: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CoachFlowHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Поиск пловцов…',
                  prefixIcon: const Icon(Icons.search_rounded, color: CoachColors.onSurfaceVariant),
                  filled: true,
                  fillColor: CoachColors.surfaceContainerLow,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterChipButton(
                      label: 'Фильтры',
                      icon: Icons.tune_rounded,
                      selected: _filtersOpen || _groupFilter != null,
                      filled: true,
                      onTap: () {
                        setState(() => _filtersOpen = !_filtersOpen);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FilterChipButton(
                      label: 'Ранг',
                      icon: Icons.sort_rounded,
                      selected: _rankFilter != null,
                      filled: false,
                      onTap: () async {
                        final id = await _showCoachPickerSheet<String>(
                          context,
                          title: 'Ранг',
                          children: [
                            ListTile(
                              title: const Text('Все ранги'),
                              onTap: () => Navigator.pop(context, ''),
                            ),
                            for (final r in SwimflowSportRank.orderedIds)
                              ListTile(
                                title: Text(SwimflowSportRank.labelRu(r)),
                                onTap: () => Navigator.pop(context, r),
                              ),
                          ],
                        );
                        if (id == null) return;
                        setState(() => _rankFilter = id.isEmpty ? null : id);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (_filtersOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Все группы'),
                      selected: _groupFilter == null,
                      onSelected: (_) => setState(() => _groupFilter = null),
                    ),
                    for (final g in SwimmerTrainingGroup.orderedIds)
                      FilterChip(
                        label: Text(SwimmerTrainingGroup.labelRu(g)),
                        selected: _groupFilter == g,
                        onSelected: (_) => setState(() => _groupFilter = g),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: SwimflowRefreshableScroll(
                color: CoachColors.primaryContainer,
                onRefresh: () => refreshCoachTeamData(ref),
                child: athletes.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (list) {
                    final lastMap = teamWorkouts.valueOrNull != null
                        ? _lastActivityByUid(teamWorkouts.valueOrNull!)
                        : <String, DateTime>{};
                    final visible = _filterList(list);
                    if (list.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 280,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Пока нет закреплённых пловцов',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Нажмите «+», чтобы создать код приглашения',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(color: CoachColors.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    if (visible.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: 200,
                            child: Center(
                              child: Text(
                                'Никого не найдено',
                                style: GoogleFonts.inter(color: CoachColors.onSurfaceVariant),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                      final a = visible[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SwimmerCard(
                          athlete: a,
                          lastActivity: lastMap[a.uid],
                          onProfile: () => context.push('/coach/swimmers/${a.uid}'),
                          onMenu: () => _showCardMenu(a),
                        ),
                      );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => CoachAthletesScreen.showInviteSheet(context),
        backgroundColor: CoachColors.secondary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  void _showCardMenu(LinkedAthlete athlete) {
    _showCoachPickerSheet<void>(
      context,
      children: [
        ListTile(
          leading: const Icon(Icons.category_outlined),
          title: const Text('Изменить группу'),
          onTap: () {
            Navigator.pop(context);
            _pickGroup(athlete);
          },
        ),
        ListTile(
          leading: const Icon(Icons.person_outline_rounded),
          title: const Text('Профиль'),
          onTap: () {
            Navigator.pop(context);
            context.push('/coach/swimmers/${athlete.uid}');
          },
        ),
      ],
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = filled ? CoachColors.primaryContainer : CoachColors.surfaceContainerLow;
    final fg = filled ? Colors.white : CoachColors.onBackground;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwimmerCard extends StatelessWidget {
  const _SwimmerCard({
    required this.athlete,
    required this.lastActivity,
    required this.onProfile,
    required this.onMenu,
  });

  final LinkedAthlete athlete;
  final DateTime? lastActivity;
  final VoidCallback onProfile;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    final age = athlete.ageYears;
    final rank = SwimflowSportRank.labelShortRu(athlete.sportRankId);
    final subtitle = [
      if (age != null) '$age лет',
      if (rank.isNotEmpty) rank,
    ].join(' • ');

    final inactive = lastActivity == null ||
        lastActivity!.isBefore(DateTime.now().subtract(const Duration(days: 5)));

  return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AthleteAvatar(athlete: athlete, showAlert: inactive),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.displayName.isEmpty ? 'Без имени' : athlete.displayName,
                      style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(fontSize: 13, color: CoachColors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onMenu,
                icon: const Icon(Icons.more_vert_rounded, color: CoachColors.onSurfaceVariant),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'Группа',
            trailing: _GroupBadge(groupId: athlete.trainingGroup),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Последняя активность',
            trailing: Text(
              _formatLastActivity(lastActivity),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onProfile,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              foregroundColor: CoachColors.onBackground,
              side: BorderSide(color: CoachColors.outlineVariant.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Профиль', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static String _formatLastActivity(DateTime? at) {
    if (at == null) return 'Нет записей';
    final now = DateTime.now();
    final day = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final time = DateFormat.Hm('ru').format(at);
    if (day == today) return 'Сегодня, $time';
    if (day == today.subtract(const Duration(days: 1))) return 'Вчера, $time';
    return DateFormat('d MMM, HH:mm', 'ru').format(at);
  }
}

class _AthleteAvatar extends StatelessWidget {
  const _AthleteAvatar({required this.athlete, required this.showAlert});

  final LinkedAthlete athlete;
  final bool showAlert;

  @override
  Widget build(BuildContext context) {
    Widget inner;
    if (athlete.avatarUrl.isNotEmpty) {
      inner = Image.network(athlete.avatarUrl, fit: BoxFit.cover);
    } else if (ProfileAvatarPresets.isValid(athlete.avatarPreset)) {
      inner = ProfileAvatarPresets.tile(athlete.avatarPreset, 56);
    } else {
      inner = ColoredBox(
        color: CoachColors.secondaryContainer.withValues(alpha: 0.25),
        child: Center(
          child: Text(
            athlete.displayName.isNotEmpty ? athlete.displayName[0].toUpperCase() : '?',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: CoachColors.primary),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(width: 56, height: 56, child: inner),
        ),
        if (showAlert)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.priority_high_rounded, size: 10, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _GroupBadge extends StatelessWidget {
  const _GroupBadge({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final label = SwimmerTrainingGroup.isValid(groupId)
        ? SwimmerTrainingGroup.labelRu(groupId)
        : 'Не указана';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CoachColors.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: CoachColors.secondary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.trailing});

  final String label;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, color: CoachColors.onSurfaceVariant)),
        const Spacer(),
        trailing,
      ],
    );
  }
}
