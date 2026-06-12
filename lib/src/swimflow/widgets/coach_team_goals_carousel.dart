import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/performance_goal_logic.dart';
import '../models/linked_athlete.dart';
import '../providers/swimflow_providers.dart';
import '../theme/coach_theme.dart';
import 'goal_status_style.dart';

class CoachTeamGoalsCarousel extends ConsumerStatefulWidget {
  const CoachTeamGoalsCarousel({required this.athletes, super.key});

  final List<LinkedAthlete> athletes;

  @override
  ConsumerState<CoachTeamGoalsCarousel> createState() => _CoachTeamGoalsCarouselState();
}

class _CoachTeamGoalsCarouselState extends ConsumerState<CoachTeamGoalsCarousel> {
  final _pageController = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final withGoals = <LinkedAthlete>[];
    for (final a in widget.athletes) {
      final goals = ref.watch(athletePerformanceGoalsFamily(a.uid)).valueOrNull ?? [];
      if (goals.isNotEmpty) withGoals.add(a);
    }
    if (withGoals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'До цели',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: CoachColors.secondary,
            ),
          ),
        ),
        SizedBox(
          height: 118,
          child: PageView.builder(
            controller: _pageController,
            itemCount: withGoals.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final a = withGoals[i];
              final goals = ref.watch(athletePerformanceGoalsFamily(a.uid)).valueOrNull ?? [];
              final swims = ref.watch(athleteCompetitionSwimsFamily(a.uid)).valueOrNull ?? [];
              final g = goals.first;
              final progress = buildPerformanceGoalProgress(goal: g, swims: swims);
              final status = performanceGoalStatusKind(progress: progress, swims: swims);
              final palette = goalStatusPalette(status);
              final subtitle = goalStatusSubtitle(progress, status);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: Colors.white,
                  elevation: 0,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => context.push('/coach/swimmers/${a.uid}?tab=3'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: palette.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: palette.accent.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(palette.icon, color: palette.accent, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  a.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: CoachColors.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: palette.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: palette.accent.withValues(alpha: 0.7)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (withGoals.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              withGoals.length,
              (i) => Container(
                width: i == _page ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _page ? CoachColors.primary : CoachColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

}
