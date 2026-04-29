import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/firestore_collections.dart';
import '../../domain/models/diary_entry.dart';
import '../../domain/models/training_plan.dart';
import '../../domain/models/training_result.dart';

class FirestoreAthleteService {
  FirestoreAthleteService(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> signInWithEntryCode(String entryCode) async {
    final query = await _firestore
        .collection(FirestoreCollections.athletes)
        .where('entryCode', isEqualTo: entryCode)
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw Exception('Код спортсмена не найден');
    }

    final athleteDoc = query.docs.first;
    final credential = await _auth.signInAnonymously();
    await _firestore.collection(FirestoreCollections.users).doc(credential.user!.uid).set({
      'email': '',
      'fullName': athleteDoc.data()['fullName'] ?? 'Спортсмен',
      'role': 'athlete',
      'approved': true,
      'athleteId': athleteDoc.id,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<TrainingPlan>> observeAthletePlans(String athleteId) {
    return _firestore
        .collection(FirestoreCollections.trainingPlans)
        .where('athleteId', isEqualTo: athleteId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TrainingPlan.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<DiaryEntry>> observeDiary(String athleteUserId) {
    return _firestore
        .collection(FirestoreCollections.diary)
        .where('athleteUserId', isEqualTo: athleteUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DiaryEntry.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addDiaryEntry({
    required String athleteUserId,
    required String note,
    required String mood,
  }) async {
    await _firestore.collection(FirestoreCollections.diary).add({
      'athleteUserId': athleteUserId,
      'note': note,
      'mood': mood,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTrainingResult({
    required String athleteUserId,
    required String trainingPlanId,
    required double distanceMeters,
    required String timeValue,
  }) async {
    await _firestore.collection(FirestoreCollections.results).add({
      'athleteUserId': athleteUserId,
      'trainingPlanId': trainingPlanId,
      'distanceMeters': distanceMeters,
      'timeValue': timeValue,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<TrainingResult>> observeResults(String athleteUserId) {
    return _firestore
        .collection(FirestoreCollections.results)
        .where('athleteUserId', isEqualTo: athleteUserId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TrainingResult.fromMap(doc.id, doc.data()))
            .toList());
  }
}
