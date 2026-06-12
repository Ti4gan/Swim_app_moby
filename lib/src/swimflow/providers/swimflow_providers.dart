import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_collections.dart';
import '../auth/auth_providers.dart';
import '../data/coach_exercise_catalog.dart';
import '../data/coach_repository.dart';
import '../data/swimflow_repository.dart';
import '../models/app_user_role.dart';
import '../models/coach_athlete_dossier.dart';
import '../models/linked_athlete.dart';
import '../models/competition_swim.dart';
import '../models/performance_goal.dart';
import '../logic/workout_stats.dart';
import '../models/swimflow_profile.dart';
import '../models/swimflow_workout.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final swimflowRepositoryProvider = Provider<SwimflowRepository?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return SwimflowRepository(ref.watch(firestoreProvider), user.uid);
});

final swimflowProfileProvider = StreamProvider<SwimflowProfile?>((ref) {
  final repo = ref.watch(swimflowRepositoryProvider);
  final email = ref.watch(authStateProvider).valueOrNull?.email ?? '';
  if (repo == null) {
    return Stream.value(null);
  }
  return repo.watchProfile().map((p) {
    if (p.email.isEmpty && email.isNotEmpty) {
      return SwimflowProfile(
        displayName: p.displayName,
        sportRankId: p.sportRankId,
        city: p.city,
        avatarPreset: p.avatarPreset,
        avatarUrl: p.avatarUrl,
        email: email,
        role: p.role,
        coachId: p.coachId,
        coachVerificationStatus: p.coachVerificationStatus,
        linkedCoachDisplayName: p.linkedCoachDisplayName,
      );
    }
    return p;
  });
});

final swimmerCoachDisplayNameProvider = StreamProvider<String?>((ref) {
  final profile = ref.watch(swimflowProfileProvider).valueOrNull;
  final coachId = profile?.coachId;
  if (coachId == null || coachId.isEmpty) {
    return Stream.value(null);
  }

  final cached = profile?.linkedCoachDisplayName?.trim();
  final db = ref.watch(firestoreProvider);
  return db.collection(FirestoreCollections.users).doc(coachId).snapshots().map((snap) {
    if (snap.exists) {
      final name = snap.data()?['displayName'] as String?;
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    if (cached != null && cached.isNotEmpty) return cached;
    return null;
  });
});

Stream<List<CoachCatalogExercise>> _catalogExercisesStream(FirebaseFirestore db) {
  return db
      .collection(FirestoreCollections.catalogExercises)
      .orderBy('sortOrder')
      .snapshots()
      .map((snap) {
        if (snap.docs.isEmpty) return kCoachExerciseCatalog;
        return snap.docs
            .map((d) => CoachCatalogExercise.fromFirestore(d.id, d.data()))
            .toList();
      })
      .handleError((_, __) => kCoachExerciseCatalog);
}

Stream<List<CoachCatalogExercise>> _customTemplatesStream(CoachRepository repo) {
  return repo
      .watchCustomWorkoutTemplates()
      .handleError((_, __) => <CoachCatalogExercise>[]);
}

final catalogExercisesProvider = StreamProvider<List<CoachCatalogExercise>>((ref) {
  final db = ref.watch(firestoreProvider);
  return _catalogExercisesStream(db);
});

final coachTemplatesRepositoryProvider = Provider<CoachRepository?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;
  return CoachRepository(ref.watch(firestoreProvider), user.uid);
});

final coachCustomTemplatesProvider = StreamProvider<List<CoachCatalogExercise>>((ref) {
  final repo = ref.watch(coachTemplatesRepositoryProvider);
  if (repo == null) {
    return Stream.value([]);
  }
  return _customTemplatesStream(repo);
});

final coachAllTemplatesProvider = Provider<AsyncValue<List<CoachCatalogExercise>>>((ref) {
  final globalAsync = ref.watch(catalogExercisesProvider);
  final customAsync = ref.watch(coachCustomTemplatesProvider);

  final waitingGlobal = globalAsync.isLoading && !globalAsync.hasValue;
  final waitingCustom = customAsync.isLoading && !customAsync.hasValue;
  if (waitingGlobal && waitingCustom) {
    return const AsyncLoading();
  }

  final global = globalAsync.hasError
      ? kCoachExerciseCatalog
      : (globalAsync.valueOrNull ?? kCoachExerciseCatalog);
  final custom = customAsync.hasError ? <CoachCatalogExercise>[] : (customAsync.valueOrNull ?? []);
  return AsyncData([...global, ...custom]);
});

final coachRepositoryProvider = Provider<CoachRepository?>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  final profile = ref.watch(swimflowProfileProvider).valueOrNull;
  if (user == null || profile == null || profile.role != AppUserRole.coach) {
    return null;
  }
  return CoachRepository(ref.watch(firestoreProvider), user.uid);
});

final coachInviteCodeProvider = StreamProvider<String?>((ref) {
  final repo = ref.watch(coachRepositoryProvider);
  if (repo == null) {
    return Stream.value(null);
  }
  return repo.watchInviteCode();
});

final coachAthletesProvider = StreamProvider<List<LinkedAthlete>>((ref) {
  final repo = ref.watch(coachRepositoryProvider);
  if (repo == null) {
    return Stream.value([]);
  }
  return repo.watchLinkedAthletes();
});

final coachTeamWorkoutsProvider = StreamProvider<List<SwimflowWorkout>>((ref) {
  final repo = ref.watch(coachRepositoryProvider);
  if (repo == null) {
    return Stream.value([]);
  }
  return repo.watchTeamRecentWorkouts();
});

final coachAthleteWorkoutsFamily = StreamProvider.family<List<SwimflowWorkout>, String>((ref, athleteUid) {
  final repo = ref.watch(coachRepositoryProvider);
  if (repo == null) {
    return Stream.value([]);
  }
  return repo.watchAthleteWorkouts(athleteUid);
});

final coachAthleteCompetitionSwimsFamily =
    StreamProvider.family<List<CompetitionSwim>, String>((ref, athleteUid) {
  final repo = ref.watch(coachRepositoryProvider);
  if (repo == null) {
    return Stream.value([]);
  }
  return repo.watchAthleteCompetitionSwims(athleteUid);
});

final coachAthleteDossierFamily = StreamProvider.family<CoachAthleteDossier, String>((ref, athleteUid) {
  final repo = ref.watch(coachRepositoryProvider);
  if (repo == null) {
    return Stream.value(CoachAthleteDossier.empty(athleteUid));
  }
  return repo.watchAthleteDossier(athleteUid);
});

final swimflowWorkoutStatsProvider = Provider<WorkoutStats>((ref) {
  final workouts = ref.watch(swimflowWorkoutsProvider).valueOrNull ?? const [];
  return workoutStatsFromList(workouts);
});

final coachGroupWorkoutStatsProvider = StreamProvider<Map<String, WorkoutStats>>((ref) {
  final repo = ref.watch(coachRepositoryProvider);
  if (repo == null) {
    return Stream.value(const {});
  }
  return repo.watchGroupWorkoutStats();
});

final swimflowWorkoutsProvider = StreamProvider<List<SwimflowWorkout>>((ref) {
  final repo = ref.watch(swimflowRepositoryProvider);
  if (repo == null) {
    return Stream.value([]);
  }
  return repo.watchWorkouts();
});

final swimflowCompetitionSwimsProvider = StreamProvider<List<CompetitionSwim>>((ref) {
  final repo = ref.watch(swimflowRepositoryProvider);
  if (repo == null) {
    return Stream.value([]);
  }
  return repo.watchCompetitionSwims();
});

final athletePerformanceGoalsFamily = StreamProvider.family<List<PerformanceGoal>, String>((ref, athleteUid) {
  final me = ref.watch(authStateProvider).valueOrNull?.uid;
  if (me == athleteUid) {
    final repo = ref.watch(swimflowRepositoryProvider);
    return repo?.watchPerformanceGoals() ?? Stream.value([]);
  }
  final coachRepo = ref.watch(coachRepositoryProvider);
  return coachRepo?.watchAthletePerformanceGoals(athleteUid) ?? Stream.value([]);
});

final athleteCompetitionSwimsFamily = StreamProvider.family<List<CompetitionSwim>, String>((ref, athleteUid) {
  final me = ref.watch(authStateProvider).valueOrNull?.uid;
  if (me == athleteUid) {
    final repo = ref.watch(swimflowRepositoryProvider);
    return repo?.watchCompetitionSwims() ?? Stream.value([]);
  }
  final coachRepo = ref.watch(coachRepositoryProvider);
  return coachRepo?.watchAthleteCompetitionSwims(athleteUid) ?? Stream.value([]);
});
