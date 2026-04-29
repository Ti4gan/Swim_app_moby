import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/constants/firestore_collections.dart';
import '../../domain/models/athlete_profile.dart';
import '../../domain/models/training_plan.dart';

class FirestoreCoachService {
  FirestoreCoachService(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Stream<List<AthleteProfile>> observeCoachAthletes(String coachId) {
    return _firestore
        .collection(FirestoreCollections.athletes)
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AthleteProfile.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<String> createAthlete({required String coachId, required String fullName}) async {
    final entryCode = _generateCode();
    final doc = _firestore.collection(FirestoreCollections.athletes).doc();
    await doc.set({
      'coachId': coachId,
      'fullName': fullName,
      'entryCode': entryCode,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return entryCode;
  }

  Future<void> submitCoachApplication({
    required String userId,
    required String fullName,
    required String email,
    required String localFilePath,
  }) async {
    final file = File(localFilePath);
    final ref = _storage.ref().child('coach_documents/$userId/${DateTime.now().millisecondsSinceEpoch}.pdf');
    await ref.putFile(file);
    final documentUrl = await ref.getDownloadURL();

    await _firestore.collection(FirestoreCollections.coaches).doc(userId).set({
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'documentUrl': documentUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection(FirestoreCollections.users).doc(userId).set({
      'role': 'coach',
      'approved': false,
    }, SetOptions(merge: true));
  }

  Future<void> createTrainingPlan({
    required String coachId,
    required String athleteId,
    required String title,
    required double distanceMeters,
    required String targetTime,
  }) async {
    final doc = _firestore.collection(FirestoreCollections.trainingPlans).doc();
    await doc.set({
      'coachId': coachId,
      'athleteId': athleteId,
      'title': title,
      'distanceMeters': distanceMeters,
      'targetTime': targetTime,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<TrainingPlan>> observeCoachPlans(String coachId) {
    return _firestore
        .collection(FirestoreCollections.trainingPlans)
        .where('coachId', isEqualTo: coachId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TrainingPlan.fromMap(doc.id, doc.data()))
            .toList());
  }

  String _generateCode() {
    final random = Random();
    final value = 100000 + random.nextInt(900000);
    return 'ATH-$value';
  }
}
