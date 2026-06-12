import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/coach_theme.dart';

class CoachTeamMonthSummaryBento extends StatelessWidget {
  const CoachTeamMonthSummaryBento({
    required this.goalsAchieved,
    required this.goalsTotal,
    required this.averageMoodLabel,
    super.key,
    this.averageMoodEmoji,
  });

  final int goalsAchieved;
  final int goalsTotal;
  final String? averageMoodLabel;
  final String? averageMoodEmoji;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CoachColors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: CoachColors.primaryContainer.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.flag_rounded, color: Colors.white),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ЦЕЛИ',
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
                      ),
                      Text(
                        goalsTotal > 0 ? '$goalsAchieved из $goalsTotal' : '—',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'выполнено',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CoachColors.secondaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    averageMoodEmoji ?? '😐',
                    style: const TextStyle(fontSize: 28, height: 1),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'НАСТРОЕНИЕ',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: CoachColors.primary.withValues(alpha: 0.75),
                        ),
                      ),
                      Text(
                        averageMoodLabel ?? 'Нет данных',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: CoachColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
