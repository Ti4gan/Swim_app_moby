import '../models/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> observeSession();
  Future<void> signInWithEmail({required String email, required String password});
  Future<String> startPhoneSignIn({required String phoneNumber});
  Future<void> verifyPhoneCode({required String verificationId, required String smsCode});
  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  });
  Future<void> signOut();
}
