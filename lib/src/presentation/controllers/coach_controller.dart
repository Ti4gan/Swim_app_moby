import '../../domain/repositories/coach_repository.dart';

class CoachController {
  CoachController(this._repository);

  final CoachRepository _repository;

  Future<String> createAthlete({required String coachId, required String fullName}) {
    return _repository.createAthlete(coachId: coachId, fullName: fullName);
  }

  Future<void> submitCoachApplication({
    required String userId,
    required String fullName,
    required String email,
    required String localFilePath,
  }) {
    return _repository.submitCoachApplication(
      userId: userId,
      fullName: fullName,
      email: email,
      localFilePath: localFilePath,
    );
  }

  Future<void> createTrainingPlan({
    required String coachId,
    required String athleteId,
    required String title,
    required double distanceMeters,
    required String targetTime,
  }) {
    return _repository.createTrainingPlan(
      coachId: coachId,
      athleteId: athleteId,
      title: title,
      distanceMeters: distanceMeters,
      targetTime: targetTime,
    );
  }
}
