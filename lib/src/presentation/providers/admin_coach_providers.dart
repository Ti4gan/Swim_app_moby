import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_admin_repository.dart';
import '../../data/repositories/firestore_coach_repository.dart';
import '../../data/services/firestore_admin_service.dart';
import '../../data/services/firestore_coach_service.dart';
import '../../domain/models/athlete_profile.dart';
import '../../domain/models/coach_application.dart';
import '../../domain/models/training_plan.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/repositories/coach_repository.dart';
import '../controllers/admin_controller.dart';
import '../controllers/coach_controller.dart';
import 'auth_providers.dart';
import 'firebase_providers.dart';

final coachServiceProvider = Provider<FirestoreCoachService>((ref) {
  return FirestoreCoachService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseStorageProvider),
  );
});

final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  return FirestoreCoachRepository(ref.watch(coachServiceProvider));
});

final coachControllerProvider = Provider<CoachController>((ref) {
  return CoachController(ref.watch(coachRepositoryProvider));
});

final coachAthletesProvider = StreamProvider<List<AthleteProfile>>((ref) {
  final user = ref.watch(authSessionProvider).valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(coachRepositoryProvider).observeCoachAthletes(user.id);
});

final coachPlansProvider = StreamProvider<List<TrainingPlan>>((ref) {
  final user = ref.watch(authSessionProvider).valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(coachRepositoryProvider).observeCoachPlans(user.id);
});

final adminServiceProvider = Provider<FirestoreAdminService>((ref) {
  return FirestoreAdminService(ref.watch(firestoreProvider));
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return FirestoreAdminRepository(ref.watch(adminServiceProvider));
});

final adminControllerProvider = Provider<AdminController>((ref) {
  return AdminController(ref.watch(adminRepositoryProvider));
});

final pendingCoachApplicationsProvider = StreamProvider<List<CoachApplication>>((ref) {
  return ref.watch(adminRepositoryProvider).observePendingCoachApplications();
});
