import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/coach_workout_in_app_providers.dart';
import '../providers/seen_notification_ids_provider.dart';
import '../router/stitch_router.dart';
import 'coach_workout_in_app_banner.dart';

class SwimflowNoticeHost extends ConsumerWidget {
  const SwimflowNoticeHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(coachWorkoutInAppListenerProvider);
    final alert = ref.watch(coachWorkoutInAppAlertProvider);
    final bottomPad = MediaQuery.paddingOf(context).bottom + 72 + 8;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (alert != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: bottomPad,
            child: CoachWorkoutInAppBanner(
              alert: alert,
              onOpen: () async {
                await ref.read(seenNotificationIdsProvider.notifier).markSeen(alert.workoutId);
                ref.read(coachWorkoutInAppAlertProvider.notifier).state = null;
                ref.read(stitchRouterProvider).push('/workout/${alert.workoutId}');
              },
              onDismiss: () async {
                await ref.read(seenNotificationIdsProvider.notifier).markSeen(alert.workoutId);
                ref.read(coachWorkoutInAppAlertProvider.notifier).state = null;
              },
            ),
          ),
      ],
    );
  }
}
