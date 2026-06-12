import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/swimflow_workout.dart';
import '../theme/tokens.dart';

double monthTotalMeters(List<SwimflowWorkout> list, DateTime month) {
  var s = 0.0;
  for (final w in list) {
    if (w.scheduledAt.year == month.year && w.scheduledAt.month == month.month) {
      s += w.distanceMeters;
    }
  }
  return s;
}

int monthTotalSeconds(List<SwimflowWorkout> list, DateTime month) {
  var s = 0;
  for (final w in list) {
    if (w.scheduledAt.year == month.year && w.scheduledAt.month == month.month) {
      s += w.durationSeconds;
    }
  }
  return s;
}

String formatMonthHoursRu(int totalSeconds) {
  if (totalSeconds <= 0) return '0м';
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  if (h > 0) return '${h}ч ${m}м';
  return '${m}м';
}

class StitchMonthSummaryBento extends StatelessWidget {
  const StitchMonthSummaryBento({
    required this.month,
    required this.workouts,
    super.key,
  });

  final DateTime month;
  final List<SwimflowWorkout> workouts;

  @override
  Widget build(BuildContext context) {
    final mMeters = monthTotalMeters(workouts, month);
    final mKm = mMeters / 1000;
    final mSec = monthTotalSeconds(workouts, month);
    final kmFmt = NumberFormat('#0.00', 'ru');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StitchColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: StitchColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.straighten_rounded, color: Colors.white),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ДИСТАНЦИЯ ЗА МЕСЯЦ',
                            style: GoogleFonts.lexend(fontSize: 11, color: Colors.white70),
                          ),
                          Text(
                            '${kmFmt.format(mKm)} км',
                            style: GoogleFonts.lexend(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${NumberFormat.decimalPattern('ru').format(mMeters.round())} м',
                            style: GoogleFonts.lexend(fontSize: 12, color: Colors.white70),
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
                    color: StitchColors.secondaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.schedule_rounded, color: StitchColors.onSecondaryContainer),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ВРЕМЯ В ВОДЕ',
                            style: GoogleFonts.lexend(
                              fontSize: 11,
                              color: StitchColors.onSecondaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            formatMonthHoursRu(mSec),
                            style: GoogleFonts.lexend(
                              fontSize: 26,
                              fontWeight: FontWeight.w600,
                              color: StitchColors.onSecondaryContainer,
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
        ),
      ],
    );
  }
}
