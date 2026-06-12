import 'package:cloud_firestore/cloud_firestore.dart';

abstract final class FirestoreCollections {
  static const users = 'users';
  static const workoutsSub = 'workouts';
  static const competitionSwimsSub = 'competition_swims';
  static const performanceGoalSub = 'performance_goal';
  static const athleteDossiersSub = 'athleteDossiers';
  static const coachInvites = 'coach_invites';
  static const coachRegistrationRequests = 'coach_registration_requests';
  static const catalogExercises = 'catalog_exercises';
  static const rankNorms = 'rank_norms';
  static const workoutTemplatesSub = 'workout_templates';

  static String userPath(String uid) => '$users/$uid';

  static CollectionReference<Map<String, dynamic>> usersCol(
    FirebaseFirestore db,
  ) =>
      db.collection(users);

  static DocumentReference<Map<String, dynamic>> userRef(
    FirebaseFirestore db,
    String uid,
  ) =>
      db.collection(users).doc(uid);

  static CollectionReference<Map<String, dynamic>> userWorkouts(
    FirebaseFirestore db,
    String uid,
  ) =>
      db.collection(users).doc(uid).collection(workoutsSub);

  static CollectionReference<Map<String, dynamic>> userCompetitionSwims(
    FirebaseFirestore db,
    String uid,
  ) =>
      db.collection(users).doc(uid).collection(competitionSwimsSub);

  static CollectionReference<Map<String, dynamic>> userPerformanceGoals(
    FirebaseFirestore db,
    String uid,
  ) =>
      db.collection(users).doc(uid).collection(performanceGoalSub);

  static DocumentReference<Map<String, dynamic>> userPerformanceGoalDoc(
    FirebaseFirestore db,
    String uid,
    String goalDocId,
  ) =>
      userPerformanceGoals(db, uid).doc(goalDocId);

  static CollectionReference<Map<String, dynamic>> coachAthleteDossiers(
    FirebaseFirestore db,
    String coachUid,
  ) =>
      db.collection(users).doc(coachUid).collection(athleteDossiersSub);

  static CollectionReference<Map<String, dynamic>> coachWorkoutTemplates(
    FirebaseFirestore db,
    String coachUid,
  ) =>
      db.collection(users).doc(coachUid).collection(workoutTemplatesSub);
}
