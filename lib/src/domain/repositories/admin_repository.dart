import '../models/coach_application.dart';

abstract class AdminRepository {
  Stream<List<CoachApplication>> observePendingCoachApplications();
  Future<void> approveCoach(String applicationId, String userId);
  Future<void> rejectCoach(String applicationId, String userId);
}
