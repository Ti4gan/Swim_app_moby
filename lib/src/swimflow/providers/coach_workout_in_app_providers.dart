import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import '../models/app_user_role.dart';
import '../models/coach_workout_in_app_alert.dart';
import '../models/swimmer_notification.dart';
import 'seen_notification_ids_provider.dart';
import 'swimflow_providers.dart';

final coachWorkoutInAppAlertProvider = StateProvider<CoachWorkoutInAppAlert?>((ref) => null);

final coachWorkoutInAppListenerProvider = Provider<void>((ref) {
  var initialSeedDone = false;

  void reset() {
    initialSeedDone = false;
    ref.read(coachWorkoutInAppAlertProvider.notifier).state = null;
  }

  bool swimmerActive() {
    final profile = ref.read(swimflowProfileProvider).valueOrNull;
    return profile != null && profile.role == AppUserRole.swimmer;
  }

  ref.listen(authStateProvider, (previous, next) {
    if (next.valueOrNull == null) reset();
  });

  ref.listen(swimflowProfileProvider, (previous, next) {
    if (next.valueOrNull?.role != AppUserRole.swimmer) reset();
  });

  ref.listen(swimflowWorkoutsProvider, (previous, next) {
    if (!next.hasValue || !swimmerActive()) return;

    final seenAsync = ref.read(seenNotificationIdsProvider);
    if (!seenAsync.hasValue) return;
    final seen = seenAsync.requireValue;

    final list = next.value!;

    if (!initialSeedDone) {
      if (list.isEmpty) return;
      final coachIds = list.where(isCoachRecordedWorkout).map((w) => w.id);
      ref.read(seenNotificationIdsProvider.notifier).ensureSeeded(coachIds);
      initialSeedDone = true;
      return;
    }

    for (final w in list) {
      if (!isCoachRecordedWorkout(w)) continue;
      if (seen.contains(w.id)) continue;
      ref.read(coachWorkoutInAppAlertProvider.notifier).state = CoachWorkoutInAppAlert(
        workoutId: w.id,
        title: w.title.trim().isEmpty ? 'Тренировка' : w.title.trim(),
        distanceMeters: w.distanceMeters,
      );
      break;
    }
  });
});
