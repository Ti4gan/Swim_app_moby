import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/app_user_role.dart';
import '../models/coach_verification_status.dart';
import '../models/swimflow_profile.dart';
import '../models/competition_swim.dart';
import '../models/performance_goal.dart';
import '../models/swimflow_workout.dart';
import '../logic/workout_calories.dart';
import '../models/swimflow_workout_title.dart';

class SwimflowRepository {
  SwimflowRepository(this._db, this._uid);

  final FirebaseFirestore _db;
  final String _uid;

  DocumentReference<Map<String, dynamic>> get _userRef =>
      FirestoreCollections.userRef(_db, _uid);

  CollectionReference<Map<String, dynamic>> get _workoutsCol =>
      FirestoreCollections.userWorkouts(_db, _uid);

  CollectionReference<Map<String, dynamic>> get _competitionSwimsCol =>
      FirestoreCollections.userCompetitionSwims(_db, _uid);

  Stream<SwimflowProfile> watchProfile() {
    return _userRef.snapshots().map((s) {
      if (!s.exists || s.data() == null) {
        return SwimflowProfile(
          displayName: '',
          sportRankId: '',
          city: '',
          avatarPreset: '',
          avatarUrl: '',
          email: '',
          role: AppUserRole.swimmer,
          coachId: null,
          coachVerificationStatus: null,
        );
      }
      return SwimflowProfile.fromUserDoc(s.data()!);
    });
  }

  Stream<List<SwimflowWorkout>> watchWorkouts() {
    return _workoutsCol.orderBy('scheduledAt', descending: true).snapshots().map(
          (s) => s.docs.map(SwimflowWorkout.fromDoc).toList(),
        );
  }

  Future<void> prefetchWorkoutsFromServer() async {
    await _workoutsCol
        .orderBy('scheduledAt', descending: true)
        .get(const GetOptions(source: Source.server));
  }

  Future<void> prefetchCompetitionSwimsFromServer() async {
    await _competitionSwimsCol
        .orderBy('eventDate', descending: true)
        .get(const GetOptions(source: Source.server));
  }

  Future<void> prefetchPerformanceGoalsFromServer() async {
    await FirestoreCollections.userPerformanceGoals(_db, _uid)
        .get(const GetOptions(source: Source.server));
  }

  Stream<List<CompetitionSwim>> watchCompetitionSwims() {
    return _competitionSwimsCol.orderBy('eventDate', descending: true).snapshots().map(
          (s) => s.docs.map(CompetitionSwim.fromDoc).toList(),
        );
  }

  Future<void> addCompetitionSwim(CompetitionSwim swim) async {
    await _competitionSwimsCol.add(swim.toFirestore());
  }

  Future<void> deleteOwnUserProfile() async {
    await _userRef.delete();
  }

  Future<void> upsertSwimmerProfile({
    required String email,
    required String displayName,
    required String sportRank,
    String city = '',
  }) async {
    await _db.runTransaction((txn) async {
      final snap = await txn.get(_userRef);
      if (!snap.exists) {
        txn.set(_userRef, {
          'email': email,
          'displayName': displayName,
          'sportRank': sportRank,
          'role': AppUserRole.swimmer,
          'city': city,
          'avatarUrl': '',
          'avatarPreset': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        txn.set(
          _userRef,
          {
            'email': email,
            'displayName': displayName,
            'sportRank': sportRank,
            'city': city,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> upsertCoachProfile({
    required String email,
    required String displayName,
    String city = '',
  }) async {
    await _db.runTransaction((txn) async {
      final snap = await txn.get(_userRef);
      if (!snap.exists) {
        txn.set(_userRef, {
          'email': email,
          'displayName': displayName,
          'sportRank': '',
          'role': AppUserRole.coach,
          'city': city,
          'avatarUrl': '',
          'avatarPreset': '',
          'profileComplete': true,
          'coachVerificationStatus': CoachVerificationConfig.enabled
              ? CoachVerificationStatus.pending
              : CoachVerificationStatus.approved,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        txn.set(
          _userRef,
          {
            'email': email,
            'displayName': displayName,
            'sportRank': '',
            'role': AppUserRole.coach,
            'city': city,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    });
  }

  Future<void> redeemInviteCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase().replaceAll(RegExp(r'\s'), '');
    if (code.isEmpty) return;
    final invRef = _db.collection(FirestoreCollections.coachInvites).doc(code);
    await _db.runTransaction((txn) async {
      final inv = await txn.get(invRef);
      if (!inv.exists) {
        throw const FormatException('invite_not_found');
      }
      final d = inv.data()!;
      final coachId = d['coachId'] as String?;
      if (coachId == null || coachId.isEmpty) {
        throw const FormatException('invite_not_found');
      }
      txn.set(
        _userRef,
        {
          'coachId': coachId,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  Future<void> syncLinkedCoachDisplayName() async {}

  Future<void> detachFromCoach() async {
    await _userRef.set(
      {
        'coachId': FieldValue.delete(),
        'coachInviteLabel': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateCoachProfileDetails({
    required String displayName,
    String city = '',
    String? avatarUrl,
  }) async {
    final patch = <String, dynamic>{
      'displayName': displayName,
      'city': city,
      'role': AppUserRole.coach,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (avatarUrl != null) {
      patch['avatarUrl'] = avatarUrl;
    }
    await _userRef.set(patch, SetOptions(merge: true));
  }

  Future<void> updateProfileDetails({
    required String displayName,
    required String sportRank,
    String city = '',
    String? avatarUrl,
    String? avatarPreset,
  }) async {
    final patch = <String, dynamic>{
      'displayName': displayName,
      'sportRank': sportRank,
      'city': city,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (avatarUrl != null) {
      patch['avatarUrl'] = avatarUrl;
    }
    if (avatarPreset != null) {
      patch['avatarPreset'] = avatarPreset;
    }
    await _userRef.set(patch, SetOptions(merge: true));
  }

  Future<void> saveFcmToken(String token) async {
    await _userRef.set(
      {
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> updateWorkoutWellbeing({
    required String workoutId,
    required int moodIndex,
    required int fatigue01to10,
    required String physicalState,
  }) async {
    final ref = _workoutsCol.doc(workoutId);
    final snap = await ref.get();
    if (!snap.exists) {
      throw StateError('workout_missing');
    }
    final data = snap.data() ?? {};
    final meta = Map<String, dynamic>.from(data['recordMeta'] as Map? ?? {});
    final sets = meta['sets'];
    final setsList = sets is List ? sets : <dynamic>[];
    final meters = (data['distanceMeters'] as num?)?.toDouble() ?? 0;
    final sec = (data['durationSeconds'] as num?)?.toInt() ?? 0;
    final calories = WorkoutCalories.estimateFromRecording(
      totalMeters: meters,
      durationSeconds: sec,
      mood: '$moodIndex',
      fatigue01to10: fatigue01to10,
      physicalState: physicalState,
      sets: setsList.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}).toList(),
      strokeLabelFallback: data['strokeLabel'] as String? ?? 'КОМПЛЕКС',
    );
    await ref.update({
      'recordMeta.mood': '$moodIndex',
      'recordMeta.fatigue': fatigue01to10.clamp(1, 10),
      'recordMeta.physicalState': physicalState,
      'recordMeta.wellbeingSaved': true,
      'recordMeta.wellbeingSavedAt': FieldValue.serverTimestamp(),
      'calories': calories,
    });
  }

  Stream<List<PerformanceGoal>> watchPerformanceGoals() {
    return FirestoreCollections.userPerformanceGoals(_db, _uid)
        .snapshots()
        .map(PerformanceGoal.listFromSnapshot);
  }

  Future<void> saveRecordedWorkout({
    required String title,
    required double totalMeters,
    required int durationSecondsTotal,
    required String mood,
    required int fatigue01to10,
    required String physicalState,
    required List<Map<String, dynamic>> sets,
  }) async {
    final workoutRef = _workoutsCol.doc();
    final resolvedTitle =
        title.trim().isEmpty ? SwimflowWorkoutTitle.generate(DateTime.now(), totalMeters) : title;
    await _db.runTransaction((txn) async {
      final userSnap = await txn.get(_userRef);
      final prevUser = userSnap.data() ?? {};
      final coachLink = prevUser['coachId'] as String?;
      final workoutPayload = {
        'title': resolvedTitle,
        'scheduledAt': Timestamp.now(),
        'distanceMeters': totalMeters,
        'durationSeconds': durationSecondsTotal,
        'poolName': 'Бассейн',
        if (coachLink != null) 'coachId': coachLink,
        'recordMeta': {
          'mood': mood,
          'fatigue': fatigue01to10,
          'physicalState': physicalState,
          'sets': sets,
        },
      };
      txn.set(workoutRef, workoutPayload);

      if (!userSnap.exists) {
        txn.set(_userRef, {
          'email': '',
          'displayName': '',
          'sportRank': '',
          'role': AppUserRole.swimmer,
          'city': '',
          'avatarUrl': '',
          'avatarPreset': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> deleteWorkout(String workoutId) async {
    await _workoutsCol.doc(workoutId).delete();
  }

  Future<void> ensureCoachRegistrationRequest() async {
    final snap = await _userRef.get();
    final d = snap.data() ?? {};
    if ((d['role'] as String?) != AppUserRole.coach) return;
    final req = _db.collection(FirestoreCollections.coachRegistrationRequests).doc(_uid);
    final existing = await req.get();
    final raw = existing.data()?['certificateUrls'];
    final urls = raw is List ? raw.map((e) => '$e').toList() : <String>[];
    await req.set(
      {
        'uid': _uid,
        'email': d['email'] ?? '',
        'displayName': d['displayName'] ?? '',
        'certificateUrls': urls,
        'status': CoachVerificationStatus.pending,
        'updatedAt': FieldValue.serverTimestamp(),
        if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> appendCoachRegistrationCertificates(List<String> downloadUrls) async {
    if (downloadUrls.isEmpty) return;
    final req = _db.collection(FirestoreCollections.coachRegistrationRequests).doc(_uid);
    await req.set(
      {
        'certificateUrls': FieldValue.arrayUnion(downloadUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> resubmitCoachVerificationAfterRejection() async {
    final reqRef = _db.collection(FirestoreCollections.coachRegistrationRequests).doc(_uid);
    final reqSnap = await reqRef.get();
    final raw = reqSnap.data()?['certificateUrls'];
    final urls = raw is List ? raw.whereType<String>().where((e) => e.trim().isNotEmpty).toList() : <String>[];
    if (urls.isEmpty) {
      throw StateError('Сначала прикрепите документы тренера');
    }
    await _userRef.set(
      {
        'coachVerificationStatus': CoachVerificationStatus.pending,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await reqRef.set(
      {
        'status': CoachVerificationStatus.pending,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
