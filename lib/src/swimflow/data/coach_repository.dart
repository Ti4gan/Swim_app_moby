import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_collections.dart';
import 'coach_exercise_catalog.dart';
import '../models/coach_athlete_dossier.dart';
import '../models/competition_swim.dart';
import '../models/performance_goal.dart';
import '../models/linked_athlete.dart';
import '../models/rank_norm_entry.dart';
import '../logic/workout_stats.dart';
import '../models/swimflow_workout.dart';
import '../models/swimflow_workout_title.dart';

class CoachRepository {
  CoachRepository(this._db, this._coachUid);

  final FirebaseFirestore _db;
  final String _coachUid;

  Stream<List<LinkedAthlete>> watchLinkedAthletes() {
    return FirestoreCollections.usersCol(_db)
        .where('coachId', isEqualTo: _coachUid)
        .snapshots()
        .map((s) => s.docs.map(LinkedAthlete.fromDoc).toList());
  }

  Stream<List<SwimflowWorkout>> watchTeamRecentWorkouts({int limit = 500}) {
    return watchLinkedAthletes().asyncExpand((athletes) {
      if (athletes.isEmpty) {
        return Stream.value(<SwimflowWorkout>[]);
      }

      late final StreamController<List<SwimflowWorkout>> controller;
      final subscriptions = <StreamSubscription<List<SwimflowWorkout>>>[];
      final lists = List.generate(athletes.length, (_) => <SwimflowWorkout>[]);

      void emit() {
        final all = <SwimflowWorkout>[];
        for (final l in lists) {
          all.addAll(l);
        }
        all.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
        if (!controller.isClosed) {
          controller.add(all.take(limit).toList());
        }
      }

      controller = StreamController<List<SwimflowWorkout>>(
        onListen: () {
          var i = 0;
          for (final a in athletes) {
            final idx = i++;
            subscriptions.add(
              watchAthleteWorkouts(a.uid, limit: 150).listen(
                (w) {
                  lists[idx] = w;
                  emit();
                },
                onError: controller.addError,
              ),
            );
          }
          emit();
        },
        onCancel: () {
          for (final s in subscriptions) {
            s.cancel();
          }
        },
      );

      return controller.stream;
    });
  }

  Future<void> prefetchTeamWorkoutsFromServer({int limit = 500}) async {
    final athletes = await FirestoreCollections.usersCol(_db)
        .where('coachId', isEqualTo: _coachUid)
        .get(const GetOptions(source: Source.server));
    for (final doc in athletes.docs) {
      await prefetchAthleteWorkoutsFromServer(doc.id, limit: limit ~/ athletes.docs.length.clamp(1, 999));
    }
  }

  Future<void> prefetchLinkedAthletesFromServer() async {
    await FirestoreCollections.usersCol(_db)
        .where('coachId', isEqualTo: _coachUid)
        .get(const GetOptions(source: Source.server));
  }

  Future<void> prefetchAthleteWorkoutsFromServer(String athleteUid, {int limit = 200}) async {
    await FirestoreCollections.userWorkouts(_db, athleteUid)
        .where('coachId', isEqualTo: _coachUid)
        .orderBy('scheduledAt', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.server));
  }

  Future<void> prefetchAthleteCompetitionSwimsFromServer(String athleteUid, {int limit = 200}) async {
    await FirestoreCollections.userCompetitionSwims(_db, athleteUid)
        .orderBy('eventDate', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.server));
  }

  Future<void> prefetchAthleteDossierFromServer(String athleteUid) async {
    await FirestoreCollections.coachAthleteDossiers(_db, _coachUid)
        .doc(athleteUid)
        .get(const GetOptions(source: Source.server));
  }

  Stream<List<SwimflowWorkout>> watchAthleteWorkouts(String athleteUid, {int limit = 200}) {
    return FirestoreCollections.userWorkouts(_db, athleteUid)
        .where('coachId', isEqualTo: _coachUid)
        .orderBy('scheduledAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(SwimflowWorkout.fromDoc).toList());
  }

  Stream<List<SwimflowWorkout>> watchAthleteWorkoutsAll(String athleteUid) {
    return FirestoreCollections.userWorkouts(_db, athleteUid)
        .snapshots()
        .map((s) => s.docs.map(SwimflowWorkout.fromDoc).toList());
  }

  Stream<Map<String, WorkoutStats>> watchGroupWorkoutStats() {
    return watchLinkedAthletes().asyncExpand((athletes) {
      if (athletes.isEmpty) {
        return Stream.value(const <String, WorkoutStats>{});
      }

      late final StreamController<Map<String, WorkoutStats>> controller;
      final subscriptions = <StreamSubscription<List<SwimflowWorkout>>>[];
      final lists = <String, List<SwimflowWorkout>>{
        for (final a in athletes) a.uid: <SwimflowWorkout>[],
      };

      void emit() {
        final out = <String, WorkoutStats>{};
        for (final e in lists.entries) {
          out[e.key] = workoutStatsFromList(e.value);
        }
        if (!controller.isClosed) {
          controller.add(out);
        }
      }

      controller = StreamController<Map<String, WorkoutStats>>(
        onListen: () {
          for (final a in athletes) {
            subscriptions.add(
              watchAthleteWorkoutsAll(a.uid).listen(
                (w) {
                  lists[a.uid] = w;
                  emit();
                },
                onError: controller.addError,
              ),
            );
          }
          emit();
        },
        onCancel: () {
          for (final s in subscriptions) {
            s.cancel();
          }
        },
      );

      return controller.stream;
    });
  }

  Stream<List<CompetitionSwim>> watchAthleteCompetitionSwims(String athleteUid, {int limit = 200}) {
    return FirestoreCollections.userCompetitionSwims(_db, athleteUid)
        .orderBy('eventDate', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(CompetitionSwim.fromDoc).toList());
  }

  Stream<List<(String athleteUid, CompetitionSwim swim)>> watchTeamCompetitionSwims({int limit = 500}) {
    return watchLinkedAthletes().asyncExpand((athletes) {
      if (athletes.isEmpty) {
        return Stream.value(<(String, CompetitionSwim)>[]);
      }

      late final StreamController<List<(String, CompetitionSwim)>> controller;
      final subscriptions = <StreamSubscription<List<CompetitionSwim>>>[];
      final lists = List.generate(athletes.length, (_) => <CompetitionSwim>[]);

      void emit() {
        final all = <(String, CompetitionSwim)>[];
        for (var i = 0; i < athletes.length; i++) {
          for (final swim in lists[i]) {
            all.add((athletes[i].uid, swim));
          }
        }
        all.sort((a, b) => b.$2.eventDate.compareTo(a.$2.eventDate));
        if (!controller.isClosed) {
          controller.add(all.take(limit).toList());
        }
      }

      controller = StreamController<List<(String, CompetitionSwim)>>(
        onListen: () {
          var i = 0;
          for (final a in athletes) {
            final idx = i++;
            subscriptions.add(
              watchAthleteCompetitionSwims(a.uid, limit: 80).listen(
                (swims) {
                  lists[idx] = swims;
                  emit();
                },
                onError: controller.addError,
              ),
            );
          }
          emit();
        },
        onCancel: () {
          for (final s in subscriptions) {
            s.cancel();
          }
        },
      );

      return controller.stream;
    });
  }

  Stream<CoachAthleteDossier> watchAthleteDossier(String athleteUid) {
    return FirestoreCollections.coachAthleteDossiers(_db, _coachUid)
        .doc(athleteUid)
        .snapshots()
        .map((s) {
      if (!s.exists) return CoachAthleteDossier.empty(athleteUid);
      return CoachAthleteDossier.fromDoc(athleteUid, s);
    });
  }

  Future<void> upsertAthleteDossier(CoachAthleteDossier dossier) async {
    await FirestoreCollections.coachAthleteDossiers(_db, _coachUid)
        .doc(dossier.athleteUid)
        .set(dossier.toFirestore(), SetOptions(merge: true));
  }

  Future<void> updateAthleteTrainingGroup(String athleteUid, String trainingGroup) async {
    await FirestoreCollections.userRef(_db, athleteUid).set(
      {
        'trainingGroup': trainingGroup,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Stream<String?> watchInviteCode() {
    return _db
        .collection(FirestoreCollections.coachInvites)
        .where('coachId', isEqualTo: _coachUid)
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : snap.docs.first.id);
  }

  Future<void> _deleteCoachInvites() async {
    final existing = await _db
        .collection(FirestoreCollections.coachInvites)
        .where('coachId', isEqualTo: _coachUid)
        .get();
    for (final doc in existing.docs) {
      await doc.reference.delete();
    }
  }

  Future<String> createOrRegenerateInvite() async {
    await _deleteCoachInvites();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random.secure();
    for (var attempt = 0; attempt < 12; attempt++) {
      final code = List.generate(6, (_) => chars[r.nextInt(chars.length)]).join();
      final ref = _db.collection(FirestoreCollections.coachInvites).doc(code);
      final snap = await ref.get();
      if (snap.exists) continue;
      await ref.set({
        'coachId': _coachUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return code;
    }
    throw StateError('invite_generation_failed');
  }

  Future<void> logAthleteWorkout({
    required String athleteUid,
    required String title,
    required double totalMeters,
    required int durationSecondsTotal,
    required DateTime scheduledAt,
    String mood = '—',
    int fatigue01to10 = 5,
    String physicalState = '—',
    List<Map<String, dynamic>> sets = const [],
  }) async {
    if (sets.isEmpty) {
      throw StateError('workout_no_sets');
    }
    if (totalMeters <= 0) {
      throw StateError('workout_zero_distance');
    }
    final athleteRef = FirestoreCollections.userRef(_db, athleteUid);
    final workoutsCol = FirestoreCollections.userWorkouts(_db, athleteUid);
    final workoutRef = workoutsCol.doc();
    final resolvedTitle =
        title.trim().isEmpty ? SwimflowWorkoutTitle.generate(scheduledAt, totalMeters) : title;

    await _db.runTransaction((txn) async {
      final userSnap = await txn.get(athleteRef);
      if (!userSnap.exists) {
        throw StateError('athlete_missing');
      }
      final u = userSnap.data() ?? {};
      if (u['coachId'] != _coachUid) {
        throw StateError('not_your_athlete');
      }
      final workoutPayload = {
        'title': resolvedTitle,
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'distanceMeters': totalMeters,
        'durationSeconds': durationSecondsTotal,
        'poolName': 'Бассейн',
        'coachId': _coachUid,
        'recordMeta': {
          'sets': sets,
          'enteredByCoach': true,
          if (mood != '—') 'mood': mood,
          if (fatigue01to10 > 0) 'fatigue': fatigue01to10,
          if (physicalState != '—') 'physicalState': physicalState,
        },
      };
      txn.set(workoutRef, workoutPayload);
    });
  }

  Stream<List<CoachCatalogExercise>> watchCustomWorkoutTemplates() {
    return FirestoreCollections.coachWorkoutTemplates(_db, _coachUid).snapshots().map((snap) {
      final list = snap.docs
          .map((d) => CoachCatalogExercise.fromFirestore(d.id, d.data(), isCustom: true))
          .toList();
      list.sort((a, b) {
        final c = a.sortOrder.compareTo(b.sortOrder);
        if (c != 0) return c;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      return list;
    });
  }

  Future<String> createCustomWorkoutTemplate(CoachCatalogExercise template) async {
    final ref = FirestoreCollections.coachWorkoutTemplates(_db, _coachUid).doc();
    await ref.set(template.toFirestore());
    return ref.id;
  }

  Future<void> deleteCustomWorkoutTemplate(String templateId) async {
    await FirestoreCollections.coachWorkoutTemplates(_db, _coachUid).doc(templateId).delete();
  }

  Stream<List<PerformanceGoal>> watchAthletePerformanceGoals(String athleteUid) {
    return FirestoreCollections.userPerformanceGoals(_db, athleteUid)
        .snapshots()
        .map(PerformanceGoal.listFromSnapshot);
  }

  Future<void> setAthletePerformanceGoal({
    required String athleteUid,
    required String strokeKey,
    required int distanceMeters,
    required int poolLengthMeters,
    required int targetTimeCentiseconds,
  }) async {
    final docId = PerformanceGoal.docIdFor(
      strokeKey: strokeKey,
      distanceMeters: distanceMeters,
      poolLengthMeters: poolLengthMeters,
    );
    await FirestoreCollections.userPerformanceGoalDoc(_db, athleteUid, docId).set(
      PerformanceGoal(
        id: docId,
        strokeKey: strokeKey,
        distanceMeters: distanceMeters,
        poolLengthMeters: poolLengthMeters,
        targetTimeCentiseconds: targetTimeCentiseconds,
        coachId: _coachUid,
        updatedAt: DateTime.now(),
      ).toFirestore(),
    );
  }

  Future<void> clearAthletePerformanceGoal({
    required String athleteUid,
    required String strokeKey,
    required int distanceMeters,
    required int poolLengthMeters,
  }) async {
    final docId = PerformanceGoal.docIdFor(
      strokeKey: strokeKey,
      distanceMeters: distanceMeters,
      poolLengthMeters: poolLengthMeters,
    );
    await FirestoreCollections.userPerformanceGoalDoc(_db, athleteUid, docId).delete();
  }

  Future<Map<String, List<RankNormEntry>>> fetchRankNorms() async {
    final snap = await _db.collection(FirestoreCollections.rankNorms).get();
    final result = <String, List<RankNormEntry>>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final rankId = data['rankId'] as String?;
      if (rankId == null) continue;
      final raw = data['entries'] as List<dynamic>? ?? [];
      result[rankId] = raw
          .map((e) => RankNormEntry.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return result;
  }
}
