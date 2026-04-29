import '../models/diary_entry.dart';
import '../models/training_plan.dart';
import '../models/training_result.dart';

abstract class AthleteRepository {
  Future<void> signInWithEntryCode(String entryCode);
  Stream<List<TrainingPlan>> observeAthletePlans(String athleteId);
  Stream<List<DiaryEntry>> observeDiary(String athleteUserId);
  Future<void> addDiaryEntry({
    required String athleteUserId,
    required String note,
    required String mood,
  });
  Future<void> addTrainingResult({
    required String athleteUserId,
    required String trainingPlanId,
    required double distanceMeters,
    required String timeValue,
  });
  Stream<List<TrainingResult>> observeResults(String athleteUserId);
}
