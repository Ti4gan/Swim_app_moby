import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/firestore_collections.dart';
import '../../domain/models/coach_application.dart';

class FirestoreAdminService {
  FirestoreAdminService(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<CoachApplication>> observePendingCoachApplications() {
    return _firestore
        .collection(FirestoreCollections.coaches)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CoachApplication.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> approveCoach(String applicationId, String userId) async {
    await _firestore.collection(FirestoreCollections.coaches).doc(applicationId).set({
      'status': 'approved',
      'approvedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection(FirestoreCollections.users).doc(userId).set({
      'role': 'coach',
      'approved': true,
    }, SetOptions(merge: true));
  }

  Future<void> rejectCoach(String applicationId, String userId) async {
    await _firestore.collection(FirestoreCollections.coaches).doc(applicationId).set({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _firestore.collection(FirestoreCollections.users).doc(userId).set({
      'role': 'athlete',
      'approved': true,
    }, SetOptions(merge: true));
  }
}
