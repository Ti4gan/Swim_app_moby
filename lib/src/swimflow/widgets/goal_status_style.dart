import 'package:flutter/material.dart';

import '../logic/performance_goal_logic.dart';
import '../theme/tokens.dart';

class GoalStatusPalette {
  const GoalStatusPalette({
    required this.accent,
    required this.border,
    required this.icon,
  });

  final Color accent;
  final Color border;
  final IconData icon;
}

GoalStatusPalette goalStatusPalette(PerformanceGoalStatusKind status) {
  switch (status) {
    case PerformanceGoalStatusKind.achieved:
      return const GoalStatusPalette(
        accent: Color(0xFF2E7D32),
        border: Color(0xFFA5D6A7),
        icon: Icons.check_circle_rounded,
      );
    case PerformanceGoalStatusKind.latestIsBestNotMet:
      return const GoalStatusPalette(
        accent: Color(0xFFF9A825),
        border: Color(0xFFFFE082),
        icon: Icons.trending_up_rounded,
      );
    case PerformanceGoalStatusKind.latestWorseThanBest:
      return const GoalStatusPalette(
        accent: Color(0xFFC62828),
        border: Color(0xFFEF9A9A),
        icon: Icons.trending_down_rounded,
      );
    case PerformanceGoalStatusKind.noResults:
      return GoalStatusPalette(
        accent: StitchColors.onSurfaceVariant,
        border: const Color(0xFFE0E0E0),
        icon: Icons.flag_outlined,
      );
  }
}

String goalStatusSubtitle(PerformanceGoalProgress progress, PerformanceGoalStatusKind status) {
  switch (status) {
    case PerformanceGoalStatusKind.achieved:
      return 'Цель достигнута';
    case PerformanceGoalStatusKind.noResults:
      return 'Нет результата на дистанции';
    case PerformanceGoalStatusKind.latestIsBestNotMet:
      return progress.bestTimeCentiseconds == null
          ? 'Нет результата'
          : 'Осталось ${formatTimeCentiseconds(progress.gapCentiseconds)}';
    case PerformanceGoalStatusKind.latestWorseThanBest:
      return 'Отставание ${formatTimeCentiseconds(progress.gapCentiseconds)}';
  }
}
