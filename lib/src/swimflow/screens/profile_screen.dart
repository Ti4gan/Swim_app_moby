import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../auth/auth_providers.dart';
import '../models/competition_swim.dart';
import '../models/performance_goal.dart';
import '../models/rank_norm_entry.dart';
import '../models/swimflow_sport_rank.dart';
import '../providers/swimflow_providers.dart';
import '../theme/tokens.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/performance_goal_panel.dart';
import '../widgets/stitch_app_header.dart';
import '../widgets/stitch_widgets.dart';

String _formatMetersRu(double m) =>
    '${NumberFormat.decimalPattern('ru').format(m.round())} м';

String _pluralResults(int n) {
  final m = n % 100;
  if (m >= 11 && m <= 14) return 'результатов';
  switch (n % 10) {
    case 1:
      return 'результат';
    case 2:
    case 3:
    case 4:
      return 'результата';
    default:
      return 'результатов';
  }
}

PerformanceGoal? _findGoal(List<PerformanceGoal> goals, String? id) {
  if (id == null) return null;
  for (final g in goals) {
    if (g.id == id) return g;
  }
  return null;
}

(String label, double gapSeconds, double bestSec, double normSec, bool met)?
    _rankGap(
  String sportRankId,
  int distanceMeters,
  String strokeKey,
  Map<String, List<RankNormEntry>> norms,
  List<CompetitionSwim> swims,
) {
  if (sportRankId.isEmpty) return null;
  final idx = SwimflowSportRank.orderedIds.indexOf(sportRankId);
  if (idx <= 0) return null;

  final nextId = SwimflowSportRank.orderedIds[idx - 1];
  final entries = norms[nextId] ?? [];
  final norm = entries.where(
    (e) => e.distanceMeters == distanceMeters && e.strokeKey == strokeKey,
  ).firstOrNull;
  if (norm == null) return null;

  final best = swims
      .where(
          (s) => s.distanceMeters == distanceMeters && s.strokeKey == strokeKey)
      .fold<int>(9999999,
          (min, s) => s.timeCentiseconds < min ? s.timeCentiseconds : min);

  if (best >= 9999999) return null;

  final gap = best - norm.timeCentiseconds;
  final normMet = gap <= 0;
  return (
    SwimflowSportRank.labelRu(nextId),
    gap.abs() / 100.0,
    best / 100.0,
    norm.timeCentiseconds / 100.0,
    normMet,
  );
}

class StitchProfileScreen extends ConsumerStatefulWidget {
  const StitchProfileScreen({super.key});

  @override
  ConsumerState<StitchProfileScreen> createState() =>
      _StitchProfileScreenState();
}

class _StitchProfileScreenState extends ConsumerState<StitchProfileScreen> {
  String? _selectedGoalId;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(swimflowProfileProvider);
    final stats = ref.watch(swimflowWorkoutStatsProvider);
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final normsAsync = ref.watch(rankNormsProvider);
    final swimsAsync = ref.watch(swimflowCompetitionSwimsProvider);
    final goalsAsync = uid != null
        ? ref.watch(athletePerformanceGoalsFamily(uid))
        : null;

    final goalList = goalsAsync?.asData?.value;
    if (goalList != null && goalList.isNotEmpty && _selectedGoalId == null) {
      _selectedGoalId = goalList.first.id;
    }

    return Scaffold(
      body: StitchPageScaffold(
        child: Column(
          children: [
            StitchMainShellHeader(
              trailing: IconButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Выйти из аккаунта?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Отмена'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Выйти'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await ref.read(firebaseAuthProvider).signOut();
                    if (context.mounted) context.go('/login');
                  }
                },
                icon:
                    const Icon(Icons.logout_rounded, color: StitchColors.outline),
              ),
            ),
            Expanded(
              child: profile.when(
                data: (p) {
                  if (p == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    children: [
                      Column(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: stitchAquaGradient,
                                ),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: ClipOval(
                                    child: SwimflowProfileAvatar(
                                        profile: p, size: 80),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: -4,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: StitchColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.verified_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(p.displayName,
                              style: Theme.of(context).textTheme.displayLarge),
                          const SizedBox(height: 4),
                          Text(
                            p.subtitle,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: StitchColors.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _statCard(
                                context,
                                Icons.pool_rounded,
                                'Всего заплывов',
                                '${stats.totalWorkouts}',
                                footer: Row(
                                  children: [
                                    const Icon(Icons.trending_up_rounded,
                                        size: 14,
                                        color: StitchColors.secondary),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '+${stats.workoutsThisMonth} в этом месяце',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: StitchColors.secondary,
                                              fontSize: 12,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _statCard(
                                context,
                                Icons.straighten_rounded,
                                'Общая дистанция',
                                _formatMetersRu(stats.totalDistanceMeters),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (uid != null) ...[
                        const SizedBox(height: 12),
                        Text('Цели по результату',
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        PerformanceGoalPanel(
                          athleteUid: uid,
                          coachMode: false,
                          embedded: true,
                          externalGoalId: _selectedGoalId,
                          onGoalChanged: (id) =>
                              setState(() => _selectedGoalId = id),
                        ),
                        ..._buildRankCards(
                          p.sportRankId,
                          normsAsync.valueOrNull ?? {},
                          swimsAsync.valueOrNull ?? [],
                          goalsAsync,
                        ),
                      ],
                      const SizedBox(height: 12),
                      ref.watch(swimflowCompetitionSwimsProvider).when(
                        data: (swims) {
                          return StitchGlassCard(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => context.go('/competitions'),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                    Icons.emoji_events_rounded,
                                                    size: 18,
                                                    color:
                                                        StitchColors.primary),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'ЗАПЛЫВЫ НА СОРЕВНОВАНИЯХ',
                                                  style: GoogleFonts.lexend(
                                                    fontSize: 11,
                                                    color: StitchColors
                                                        .onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${swims.length} ${_pluralResults(swims.length)}',
                                              style: GoogleFonts.lexend(
                                                fontSize: 24,
                                                fontWeight: FontWeight.w600,
                                                color: StitchColors
                                                    .onPrimaryFixedVariant,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Лучший результат — после выбора длины бассейна и «Применить фильтры»',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 64,
                                        height: 64,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color:
                                                  StitchColors.secondaryFixed,
                                              width: 4),
                                          color: Colors.white,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Color(0x1A000000),
                                              blurRadius: 4,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                            Icons.pool_rounded,
                                            color: StitchColors.secondary,
                                            size: 28),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(Icons.chevron_right_rounded,
                                          color: StitchColors.outline
                                              .withValues(alpha: 0.6)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        loading: () => StitchGlassCard(
                          child: SizedBox(
                            height: 88,
                            child: Center(
                              child: CircularProgressIndicator(
                                color:
                                    StitchColors.primary.withValues(alpha: 0.4),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                        error: (e, _) =>
                            StitchGlassCard(child: Text('$e')),
                      ),
                      const SizedBox(height: 20),
                      StitchGlassCard(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.push('/settings'),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: StitchColors.primaryFixed
                                          .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                        Icons.settings_rounded,
                                        color: StitchColors.primary),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Настройки',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        Text(
                                          'Имя, фото, тренер',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.chevron_right_rounded,
                                      color: StitchColors.outline
                                          .withValues(alpha: 0.6)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRankCards(
    String sportRankId,
    Map<String, List<RankNormEntry>> norms,
    List<CompetitionSwim> swims,
    AsyncValue<List<PerformanceGoal>>? goalsAsync,
  ) {
    if (goalsAsync == null) return [];
    final goals = goalsAsync.asData?.value;
    if (goals == null || goals.isEmpty || _selectedGoalId == null) return [];

    final goal = _findGoal(goals, _selectedGoalId);
    if (goal == null) return [];

    final gap = _rankGap(
      sportRankId,
      goal.distanceMeters,
      goal.strokeKey,
      norms,
      swims,
    );
    if (gap == null) return [];

    final (label, gapSec, bestSec, normSec, met) = gap;

    return [
      const SizedBox(height: 12),
      StitchGlassCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    met ? Icons.check_circle_rounded : Icons.emoji_events_rounded,
                    color: met ? const Color(0xFF2E7D32) : StitchColors.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'До следующего разряда',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: met ? const Color(0xFF2E7D32) : StitchColors.onBackground,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: met
                            ? const Color(0xFF2E7D32).withValues(alpha: 0.15)
                            : StitchColors.primaryFixed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: met ? const Color(0xFF2E7D32) : StitchColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    met ? 'Выполнен' : SwimflowSportRank.formatSeconds(gapSec),
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: met ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                met
                    ? 'Лучший: ${SwimflowSportRank.formatSeconds(bestSec)} · Норматив: ${SwimflowSportRank.formatSeconds(normSec)}'
                    : 'Текущий лучший: ${SwimflowSportRank.formatSeconds(bestSec)} · Норматив: ${SwimflowSportRank.formatSeconds(normSec)}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: StitchColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _statCard(
    BuildContext context,
    IconData icon,
    String cap,
    String value, {
    Widget? footer,
    Widget? sub,
  }) {
    return StitchGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: StitchColors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      cap.toUpperCase(),
                      style: GoogleFonts.lexend(
                          fontSize: 10, color: StitchColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: StitchColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 40),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: footer ?? sub ?? const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
