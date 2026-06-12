import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/swimmer_notification.dart';
import 'seen_notification_ids_provider.dart';
import 'swimflow_providers.dart';

export 'seen_notification_ids_provider.dart' show seenNotificationIdsProvider;

final swimmerCoachNotificationsProvider = Provider<List<SwimmerNotification>>((ref) {
  final workouts = ref.watch(swimflowWorkoutsProvider).valueOrNull ?? [];
  final list = workouts.where(isCoachRecordedWorkout).map(SwimmerNotification.fromWorkout).toList();
  list.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
  return list;
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final items = ref.watch(swimmerCoachNotificationsProvider);
  final seen = ref.watch(seenNotificationIdsProvider).valueOrNull ?? {};
  return items.where((n) => !seen.contains(n.workoutId)).length;
});
