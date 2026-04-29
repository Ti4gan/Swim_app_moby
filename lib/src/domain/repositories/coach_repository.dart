import '../models/athlete_profile.dart';
import '../models/training_plan.dart';

abstract class CoachRepository {
  Stream<List<AthleteProfile>> observeCoachAthletes(String coachId);
  Future<String> createAthlete({required String coachId, required String fullName});
  Future<void> submitCoachApplication({
    required String userId,
    required String fullName,
    required String email,
    required String localFilePath,
  });
  Future<void> createTrainingPlan({
    required String coachId,
    required String athleteId,
    required String title,
    required double distanceMeters,
    required String targetTime,
  });
  Stream<List<TrainingPlan>> observeCoachPlans(String coachId);
}
