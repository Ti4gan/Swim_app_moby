import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firestore_collections.dart';
import '../../domain/models/app_user.dart';

class FirebaseAuthService {
  FirebaseAuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<AppUser?> observeSession() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(firebaseUser.uid)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return AppUser.fromMap(doc.id, doc.data()!);
    });
  }

  Future<void> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<String> startPhoneSignIn(String phoneNumber) async {
    String? verificationId;
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: (error) {
        throw error;
      },
      codeSent: (id, _) {
        verificationId = id;
      },
      codeAutoRetrievalTimeout: (id) {
        verificationId = id;
      },
    );
    if (verificationId == null) {
      throw Exception('Не удалось отправить SMS-код');
    }
    return verificationId!;
  }

  Future<void> verifyPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(result.user!.uid)
        .set({
          'email': result.user?.phoneNumber ?? '',
          'fullName': 'Спортсмен',
          'role': 'athlete',
          'approved': true,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _firestore
        .collection(FirestoreCollections.users)
        .doc(credential.user!.uid)
        .set({
          'email': email,
          'fullName': fullName,
          'role': 'athlete',
          'approved': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> signOut() => _auth.signOut();
}
