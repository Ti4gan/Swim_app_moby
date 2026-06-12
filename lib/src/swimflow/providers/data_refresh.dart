import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'swimflow_providers.dart';

Future<void> refreshSwimmerWorkouts(WidgetRef ref) async {
  final repo = ref.read(swimflowRepositoryProvider);
  if (repo != null) {
    await repo.prefetchWorkoutsFromServer();
  }
  ref.invalidate(swimflowWorkoutsProvider);
  await ref.read(swimflowWorkoutsProvider.future);
}

Future<void> refreshSwimmerCompetitionSwims(WidgetRef ref) async {
  final repo = ref.read(swimflowRepositoryProvider);
  if (repo != null) {
    await repo.prefetchCompetitionSwimsFromServer();
  }
  ref.invalidate(swimflowCompetitionSwimsProvider);
  await ref.read(swimflowCompetitionSwimsProvider.future);
}

Future<void> refreshSwimmerDashboard(WidgetRef ref) async {
  final uid = ref.read(authStateProvider).valueOrNull?.uid;
  final repo = ref.read(swimflowRepositoryProvider);
  if (repo != null) {
    await Future.wait([
      repo.prefetchWorkoutsFromServer(),
      repo.prefetchCompetitionSwimsFromServer(),
      repo.prefetchPerformanceGoalsFromServer(),
    ]);
  }
  ref.invalidate(swimflowWorkoutsProvider);
  ref.invalidate(swimflowCompetitionSwimsProvider);
  if (uid != null) {
    ref.invalidate(athletePerformanceGoalsFamily(uid));
  }
  await Future.wait([
    ref.read(swimflowWorkoutsProvider.future),
    ref.read(swimflowCompetitionSwimsProvider.future),
    if (uid != null) ref.read(athletePerformanceGoalsFamily(uid).future),
  ]);
}

Future<void> refreshCoachTeamData(WidgetRef ref) async {
  final repo = ref.read(coachRepositoryProvider);
  if (repo != null) {
    await Future.wait([
      repo.prefetchLinkedAthletesFromServer(),
      repo.prefetchTeamWorkoutsFromServer(),
    ]);
  }
  ref.invalidate(coachAthletesProvider);
  ref.invalidate(coachTeamWorkoutsProvider);
  await Future.wait([
    ref.read(coachAthletesProvider.future),
    ref.read(coachTeamWorkoutsProvider.future),
  ]);
}

Future<void> refreshCoachAthleteDetail(WidgetRef ref, String athleteUid) async {
  final repo = ref.read(coachRepositoryProvider);
  if (repo != null) {
    await Future.wait([
      repo.prefetchAthleteWorkoutsFromServer(athleteUid),
      repo.prefetchAthleteCompetitionSwimsFromServer(athleteUid),
      repo.prefetchAthleteDossierFromServer(athleteUid),
    ]);
  }
  ref.invalidate(coachAthleteWorkoutsFamily(athleteUid));
  ref.invalidate(coachAthleteCompetitionSwimsFamily(athleteUid));
  ref.invalidate(coachAthleteDossierFamily(athleteUid));
  await Future.wait([
    ref.read(coachAthleteWorkoutsFamily(athleteUid).future),
    ref.read(coachAthleteCompetitionSwimsFamily(athleteUid).future),
  ]);
}
