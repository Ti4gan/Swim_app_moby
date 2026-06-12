import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../logic/performance_goal_logic.dart';
import '../models/competition_swim.dart';
import '../models/performance_goal.dart';
import '../theme/tokens.dart';
import 'competition_swims_panel.dart';
import 'goal_status_style.dart';

class SwimmerGoalsCarousel extends StatefulWidget {
  const SwimmerGoalsCarousel({
    required this.goals,
    required this.swims,
    required this.pageController,
    required this.onPageChanged,
    super.key,
  });

  final List<PerformanceGoal> goals;
  final List<CompetitionSwim> swims;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  @override
  State<SwimmerGoalsCarousel> createState() => _SwimmerGoalsCarouselState();
}

class _SwimmerGoalsCarouselState extends State<SwimmerGoalsCarousel> {
  int _page = 0;

  String _goalTitle(PerformanceGoal g) =>
      '${competitionStrokeRu(g.strokeKey)} · ${g.distanceMeters} м · ${g.poolLengthMeters} м';

  @override
  Widget build(BuildContext context) {
    if (widget.goals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'До цели',
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: StitchColors.primary,
            ),
          ),
        ),
        SizedBox(
          height: 118,
          child: PageView.builder(
            controller: widget.pageController,
            itemCount: widget.goals.length,
            onPageChanged: (i) {
              setState(() => _page = i);
              widget.onPageChanged(i);
            },
            itemBuilder: (context, i) {
              final g = widget.goals[i];
              final progress = buildPerformanceGoalProgress(goal: g, swims: widget.swims);
              final status = performanceGoalStatusKind(progress: progress, swims: widget.swims);
              final palette = goalStatusPalette(status);
              final subtitle = goalStatusSubtitle(progress, status);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: () => context.go('/profile'),
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
                                  _goalTitle(g),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lexend(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: StitchColors.onBackground,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.lexend(
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
        if (widget.goals.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.goals.length,
              (i) => Container(
                width: i == _page ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _page ? StitchColors.primary : StitchColors.surfaceContainerLow,
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
