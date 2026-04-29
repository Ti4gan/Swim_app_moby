import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/firestore_athlete_repository.dart';
import '../../data/services/firestore_athlete_service.dart';
import '../../domain/models/diary_entry.dart';
import '../../domain/models/training_plan.dart';
import '../../domain/models/training_result.dart';
import '../../domain/repositories/athlete_repository.dart';
import '../controllers/athlete_controller.dart';
import 'auth_providers.dart';
import 'firebase_providers.dart';

final athleteServiceProvider = Provider<FirestoreAthleteService>((ref) {
  return FirestoreAthleteService(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

final athleteRepositoryProvider = Provider<AthleteRepository>((ref) {
  return FirestoreAthleteRepository(ref.watch(athleteServiceProvider));
});

final athleteControllerProvider = Provider<AthleteController>((ref) {
  return AthleteController(ref.watch(athleteRepositoryProvider));
});

final athletePlansProvider = StreamProvider<List<TrainingPlan>>((ref) {
  final user = ref.watch(authSessionProvider).valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  final athleteId = user.athleteId;
  if (athleteId == null || athleteId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(athleteRepositoryProvider).observeAthletePlans(athleteId);
});

final athleteDiaryProvider = StreamProvider<List<DiaryEntry>>((ref) {
  final user = ref.watch(authSessionProvider).valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(athleteRepositoryProvider).observeDiary(user.id);
});

final athleteResultsProvider = StreamProvider<List<TrainingResult>>((ref) {
  final user = ref.watch(authSessionProvider).valueOrNull;
  if (user == null) {
    return Stream.value(const []);
  }
  return ref.watch(athleteRepositoryProvider).observeResults(user.id);
});
