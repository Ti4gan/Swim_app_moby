import '../../domain/repositories/auth_repository.dart';

class AuthController {
  AuthController(this._repository);

  final AuthRepository _repository;

  Future<void> signInWithEmail({required String email, required String password}) {
    return _repository.signInWithEmail(email: email, password: password);
  }

  Future<String> startPhoneSignIn({required String phoneNumber}) {
    return _repository.startPhoneSignIn(phoneNumber: phoneNumber);
  }

  Future<void> verifyPhoneCode({required String verificationId, required String smsCode}) {
    return _repository.verifyPhoneCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) {
    return _repository.registerWithEmail(
      email: email,
      password: password,
      fullName: fullName,
    );
  }

  Future<void> signOut() => _repository.signOut();
}
