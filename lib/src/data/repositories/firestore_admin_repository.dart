import '../../domain/models/coach_application.dart';
import '../../domain/repositories/admin_repository.dart';
import '../services/firestore_admin_service.dart';

class FirestoreAdminRepository implements AdminRepository {
  FirestoreAdminRepository(this._service);

  final FirestoreAdminService _service;

  @override
  Stream<List<CoachApplication>> observePendingCoachApplications() {
    return _service.observePendingCoachApplications();
  }

  @override
  Future<void> approveCoach(String applicationId, String userId) {
    return _service.approveCoach(applicationId, userId);
  }

  @override
  Future<void> rejectCoach(String applicationId, String userId) {
    return _service.rejectCoach(applicationId, userId);
  }
}
