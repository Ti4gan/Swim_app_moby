import 'package:cloud_firestore/cloud_firestore.dart';

import '../logic/workout_calories.dart';
import '../logic/workout_date_label.dart';
import '../logic/workout_derived.dart';

class SwimflowWorkout {
  const SwimflowWorkout({
    required this.id,
    required this.title,
    required this.scheduledAt,
    required this.listSubtitle,
    required this.strokeLabel,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.pacePer100,
    required this.calories,
    required this.laps,
    required this.poolName,
    required this.detailDateLabel,
    this.recordMeta,
    this.coachId,
    this.athleteUid,
    this.athleteDisplayName,
  });

  final String id;
  final String title;
  final DateTime scheduledAt;
  final String listSubtitle;
  final String strokeLabel;
  final double distanceMeters;
  final int durationSeconds;
  final String pacePer100;
  final int calories;
  final int laps;
  final String poolName;
  final String detailDateLabel;
  final Map<String, dynamic>? recordMeta;
  final String? coachId;
  final String? athleteUid;
  final String? athleteDisplayName;

  int get durationMinutes =>
      durationSeconds <= 0 ? 0 : (durationSeconds / 60).ceil().clamp(1, 99999);

  factory SwimflowWorkout.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final ts = m['scheduledAt'];
    DateTime at;
    if (ts is Timestamp) {
      at = ts.toDate();
    } else {
      at = DateTime.now();
    }
    final dm = (m['durationMinutes'] as num?)?.toInt() ?? 0;
    final ds = (m['durationSeconds'] as num?)?.toInt();
    final durationSeconds = ds ?? (dm > 0 ? dm * 60 : 0);
    final distanceMeters = (m['distanceMeters'] as num?)?.toDouble() ?? 0;
    Map<String, dynamic>? meta;
    final rawMeta = m['recordMeta'];
    if (rawMeta is Map) {
      meta = Map<String, dynamic>.from(rawMeta);
    }
    final storedStroke = m['strokeLabel'] as String? ?? '';
    final strokeLabel = workoutStrokeLabelFromMeta(stored: storedStroke, recordMeta: meta);
    final paceStored = m['pacePer100'] as String? ?? '';
    final pacePer100 = paceStored.trim().isEmpty || paceStored == '—'
        ? workoutPacePer100(distanceMeters: distanceMeters, durationSeconds: durationSeconds)
        : paceStored;
    final lapsStored = (m['laps'] as num?)?.toInt() ?? 0;
    final laps = lapsStored > 0 ? lapsStored : workoutLaps(distanceMeters);
    final caloriesStored = (m['calories'] as num?)?.toInt() ?? 0;
    final calories = caloriesStored > 0
        ? caloriesStored
        : WorkoutCalories.estimateFromRecording(
            totalMeters: distanceMeters,
            durationSeconds: durationSeconds,
            mood: meta?['mood'],
            fatigue01to10: _parseFatigue(meta?['fatigue']),
            physicalState: '${meta?['physicalState'] ?? 'normal'}',
            sets: _parseSets(meta?['sets']),
            strokeLabelFallback: strokeLabel,
          );
    final athleteUid =
        m['athleteUid'] as String? ?? workoutAthleteUidFromDocPath(doc.reference.path);
    return SwimflowWorkout(
      id: doc.id,
      title: m['title'] as String? ?? '',
      scheduledAt: at,
      listSubtitle: workoutListSubtitle(
        stored: m['listSubtitle'] as String? ?? '',
        scheduledAt: at,
        distanceMeters: distanceMeters,
        recordMeta: meta,
      ),
      strokeLabel: strokeLabel,
      distanceMeters: distanceMeters,
      durationSeconds: durationSeconds,
      pacePer100: pacePer100,
      calories: calories,
      laps: laps,
      poolName: m['poolName'] as String? ?? '',
      detailDateLabel: workoutDetailDateLabelRu(at),
      recordMeta: meta,
      coachId: m['coachId'] as String?,
      athleteUid: athleteUid,
      athleteDisplayName: m['athleteDisplayName'] as String?,
    );
  }

  static int _parseFatigue(dynamic v) {
    if (v is num) return v.round().clamp(1, 10);
    return int.tryParse('$v')?.clamp(1, 10) ?? 5;
  }

  static List<Map<String, dynamic>> _parseSets(dynamic raw) {
    if (raw is! List) return const [];
    final out = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(e);
      } else if (e is Map) {
        out.add(Map<String, dynamic>.from(e));
      }
    }
    return out;
  }
}
