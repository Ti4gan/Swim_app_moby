import '../../domain/models/diary_entry.dart';
import '../../domain/models/training_plan.dart';
import '../../domain/models/training_result.dart';
import '../../domain/repositories/athlete_repository.dart';
import '../services/firestore_athlete_service.dart';

class FirestoreAthleteRepository implements AthleteRepository {
  FirestoreAthleteRepository(this._service);

  final FirestoreAthleteService _service;

  @override
  Future<void> signInWithEntryCode(String entryCode) => _service.signInWithEntryCode(entryCode);

  @override
  Stream<List<TrainingPlan>> observeAthletePlans(String athleteId) => _service.observeAthletePlans(athleteId);

  @override
  Stream<List<DiaryEntry>> observeDiary(String athleteUserId) => _service.observeDiary(athleteUserId);

  @override
  Future<void> addDiaryEntry({required String athleteUserId, required String note, required String mood}) {
    return _service.addDiaryEntry(athleteUserId: athleteUserId, note: note, mood: mood);
  }

  @override
  Future<void> addTrainingResult({
    required String athleteUserId,
    required String trainingPlanId,
    required double distanceMeters,
    required String timeValue,
  }) {
    return _service.addTrainingResult(
      athleteUserId: athleteUserId,
      trainingPlanId: trainingPlanId,
      distanceMeters: distanceMeters,
      timeValue: timeValue,
    );
  }

  @override
  Stream<List<TrainingResult>> observeResults(String athleteUserId) => _service.observeResults(athleteUserId);
}
