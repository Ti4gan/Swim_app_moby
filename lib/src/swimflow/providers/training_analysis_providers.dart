import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/firestore_collections.dart';
import '../models/competition_swim.dart';
import '../models/swimflow_workout.dart';
import '../models/training_analysis.dart';
import 'swimflow_providers.dart';

final trainingAnalysisProvider =
    Provider.family<List<TrainingAnalysis>, String>((ref, athleteUid) {
  final swims = ref.watch(coachAthleteCompetitionSwimsFamily(athleteUid)).valueOrNull ?? [];
  final workouts =
      ref.watch(coachAthleteWorkoutsAllFamily(athleteUid)).valueOrNull ?? [];

  return _computeAnalysis(athleteUid, swims, workouts);
});

List<TrainingAnalysis> _computeAnalysis(
  String athleteId,
  List<CompetitionSwim> swims,
  List<SwimflowWorkout> workouts,
) {
  if (swims.length < 2) return [];

  final grouped = <String, List<CompetitionSwim>>{};
  for (final s in swims) {
    final key = '${s.distanceMeters}_${s.strokeKey}';
    grouped.putIfAbsent(key, () => []).add(s);
  }

  final results = <TrainingAnalysis>[];
  for (final entry in grouped.entries) {
    final sameDistance = entry.value;
    sameDistance.sort((a, b) => a.eventDate.compareTo(b.eventDate));
    if (sameDistance.length < 2) continue;

    for (var i = 0; i < sameDistance.length - 1; i++) {
      final prev = sameDistance[i];
      final curr = sameDistance[i + 1];
      final analysis = _pairAnalysis(athleteId, prev, curr, workouts);
      if (analysis != null) {
        results.add(analysis);
      }
    }
  }

  results.sort((a, b) => b.endDate.compareTo(a.endDate));
  return results;
}

TrainingAnalysis? _pairAnalysis(
  String athleteId,
  CompetitionSwim prev,
  CompetitionSwim curr,
  List<SwimflowWorkout> workouts,
) {
  final startDate = prev.eventDate;
  final endDate = curr.eventDate;

  if (endDate.isBefore(startDate) || endDate.isAtSameMomentAs(startDate)) {
    return null;
  }

  final cycleWorkouts = workouts.where((w) {
    final at = w.scheduledAt;
    return at.isAfter(startDate) && at.isBefore(endDate) ||
        at.isAtSameMomentAs(startDate) && !at.isAtSameMomentAs(endDate);
  }).toList();

  final prevSec = prev.timeCentiseconds;
  final currSec = curr.timeCentiseconds;

  final improvement = (prevSec - currSec) / 100.0;
  final progressPercent =
      prevSec > 0 ? ((prevSec - currSec) / prevSec) * 100 : 0.0;
  final workoutsCount = cycleWorkouts.length;
  final avgEfficiency =
      workoutsCount > 0 ? progressPercent / workoutsCount : 0.0;

  String efficiencyLevel;
  if (progressPercent > 5) {
    efficiencyLevel = 'high';
  } else if (progressPercent >= 1) {
    efficiencyLevel = 'medium';
  } else if (progressPercent >= 0) {
    efficiencyLevel = 'low';
  } else {
    efficiencyLevel = 'negative';
  }

  final id = '${curr.id}_${prev.id}';
  return TrainingAnalysis(
    id: id,
    athleteId: athleteId,
    previousCompetitionId: prev.id,
    currentCompetitionId: curr.id,
    previousResultCentiseconds: prev.timeCentiseconds,
    currentResultCentiseconds: curr.timeCentiseconds,
    distanceMeters: prev.distanceMeters,
    strokeKey: prev.strokeKey,
    workoutsCount: workoutsCount,
    improvementInSeconds: improvement,
    progressPercent: progressPercent,
    averageWorkoutEfficiency: avgEfficiency,
    efficiencyLevel: efficiencyLevel,
    startDate: startDate,
    endDate: endDate,
  );
}

Future<void> saveTrainingAnalysis(
  FirebaseFirestore db,
  TrainingAnalysis analysis,
) async {
  final ref = FirestoreCollections.userTrainingAnalysis(db, analysis.athleteId);
  await ref.doc(analysis.id).set(analysis.toFirestore());
}
