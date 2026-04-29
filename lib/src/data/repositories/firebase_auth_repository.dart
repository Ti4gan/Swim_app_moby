import '../../domain/models/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/firebase_auth_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._service);

  final FirebaseAuthService _service;

  @override
  Stream<AppUser?> observeSession() => _service.observeSession();

  @override
  Future<void> signInWithEmail({required String email, required String password}) {
    return _service.signInWithEmail(email, password);
  }

  @override
  Future<String> startPhoneSignIn({required String phoneNumber}) {
    return _service.startPhoneSignIn(phoneNumber);
  }

  @override
  Future<void> verifyPhoneCode({required String verificationId, required String smsCode}) {
    return _service.verifyPhoneCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  @override
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _service.registerWithEmail(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  @override
  Future<void> signOut() => _service.signOut();
}
