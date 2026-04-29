import '../../domain/models/athlete_profile.dart';
import '../../domain/models/training_plan.dart';
import '../../domain/repositories/coach_repository.dart';
import '../services/firestore_coach_service.dart';

class FirestoreCoachRepository implements CoachRepository {
  FirestoreCoachRepository(this._service);

  final FirestoreCoachService _service;

  @override
  Stream<List<AthleteProfile>> observeCoachAthletes(String coachId) {
    return _service.observeCoachAthletes(coachId);
  }

  @override
  Future<String> createAthlete({required String coachId, required String fullName}) {
    return _service.createAthlete(coachId: coachId, fullName: fullName);
  }

  @override
  Future<void> submitCoachApplication({
    required String userId,
    required String fullName,
    required String email,
    required String localFilePath,
  }) {
    return _service.submitCoachApplication(
      userId: userId,
      fullName: fullName,
      email: email,
      localFilePath: localFilePath,
    );
  }

  @override
  Future<void> createTrainingPlan({
    required String coachId,
    required String athleteId,
    required String title,
    required double distanceMeters,
    required String targetTime,
  }) {
    return _service.createTrainingPlan(
      coachId: coachId,
      athleteId: athleteId,
      title: title,
      distanceMeters: distanceMeters,
      targetTime: targetTime,
    );
  }

  @override
  Stream<List<TrainingPlan>> observeCoachPlans(String coachId) {
    return _service.observeCoachPlans(coachId);
  }
}
