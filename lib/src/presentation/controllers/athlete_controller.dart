import '../../domain/repositories/athlete_repository.dart';

class AthleteController {
  AthleteController(this._repository);

  final AthleteRepository _repository;

  Future<void> signInWithEntryCode(String entryCode) => _repository.signInWithEntryCode(entryCode);

  Future<void> addDiaryEntry({
    required String athleteUserId,
    required String note,
    required String mood,
  }) {
    return _repository.addDiaryEntry(athleteUserId: athleteUserId, note: note, mood: mood);
  }

  Future<void> addTrainingResult({
    required String athleteUserId,
    required String trainingPlanId,
    required double distanceMeters,
    required String timeValue,
  }) {
    return _repository.addTrainingResult(
      athleteUserId: athleteUserId,
      trainingPlanId: trainingPlanId,
      distanceMeters: distanceMeters,
      timeValue: timeValue,
    );
  }
}
