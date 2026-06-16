import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/coach_notification.dart';
import '../models/competition_swim.dart';
import 'seen_coach_notification_ids_provider.dart';
import 'swimflow_providers.dart';

export 'seen_coach_notification_ids_provider.dart' show seenCoachNotificationIdsProvider;

final coachTeamCompetitionSwimsProvider =
    StreamProvider<List<(String athleteUid, CompetitionSwim swim)>>((ref) {
  final repo = ref.watch(coachRepositoryProvider);
  if (repo == null) {
    return Stream.value([]);
  }
  return repo.watchTeamCompetitionSwims();
});

final coachNotificationsProvider = Provider<List<CoachNotification>>((ref) {
  final athletes = ref.watch(coachAthletesProvider).valueOrNull ?? [];
  final names = {for (final a in athletes) a.uid: a.displayName};

  final workouts = ref.watch(coachTeamWorkoutsProvider).valueOrNull ?? [];
  final wellbeing = workouts
      .where(isSwimmerWellbeingNotification)
      .map((w) {
        final uid = w.athleteUid ?? '';
        return CoachNotification.fromWellbeingWorkout(
          workout: w,
          athleteName: names[uid]?.trim().isNotEmpty == true ? names[uid]!.trim() : 'Пловец',
        );
      })
      .where((n) => n.athleteUid.isNotEmpty);

  final swims = ref.watch(coachTeamCompetitionSwimsProvider).valueOrNull ?? [];
  final competition = swims.map((row) {
    final uid = row.$1;
    final swim = row.$2;
    return CoachNotification.fromCompetitionSwim(
      athleteUid: uid,
      athleteName: names[uid]?.trim().isNotEmpty == true ? names[uid]!.trim() : 'Пловец',
      swim: swim,
    );
  });

  final list = [...wellbeing, ...competition].toList();
  list.sort((a, b) => b.at.compareTo(a.at));
  return list;
});

final unreadCoachNotificationsCountProvider = Provider<int>((ref) {
  final items = ref.watch(coachNotificationsProvider);
  final seen = ref.watch(seenCoachNotificationIdsProvider);
  return items.where((n) => !seen.contains(n.id)).length;
});
