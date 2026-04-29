import '../../domain/repositories/admin_repository.dart';

class AdminController {
  AdminController(this._repository);

  final AdminRepository _repository;

  Future<void> approveCoach(String applicationId, String userId) {
    return _repository.approveCoach(applicationId, userId);
  }

  Future<void> rejectCoach(String applicationId, String userId) {
    return _repository.rejectCoach(applicationId, userId);
  }
}
