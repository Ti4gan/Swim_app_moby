import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/coach_workout_in_app_alert.dart';
import '../theme/tokens.dart';

class CoachWorkoutInAppBanner extends StatelessWidget {
  const CoachWorkoutInAppBanner({
    required this.alert,
    required this.onOpen,
    required this.onDismiss,
    super.key,
  });

  final CoachWorkoutInAppAlert alert;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final meters = alert.distanceMeters.round();

    return Material(
      elevation: 8,
      shadowColor: StitchColors.primary.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      color: StitchColors.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                'Тренер добавил: «${alert.title}» — $meters м',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                foregroundColor: StitchColors.secondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Открыть',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
              padding: const EdgeInsets.all(6),
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ),
    );
  }
}
