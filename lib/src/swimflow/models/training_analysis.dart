import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingAnalysis {
  const TrainingAnalysis({
    required this.id,
    required this.athleteId,
    required this.previousCompetitionId,
    required this.currentCompetitionId,
    required this.previousResultCentiseconds,
    required this.currentResultCentiseconds,
    required this.distanceMeters,
    required this.strokeKey,
    required this.workoutsCount,
    required this.improvementInSeconds,
    required this.progressPercent,
    required this.averageWorkoutEfficiency,
    required this.efficiencyLevel,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String athleteId;
  final String previousCompetitionId;
  final String currentCompetitionId;
  final int previousResultCentiseconds;
  final int currentResultCentiseconds;
  final int distanceMeters;
  final String strokeKey;
  final int workoutsCount;
  final double improvementInSeconds;
  final double progressPercent;
  final double averageWorkoutEfficiency;
  final String efficiencyLevel;
  final DateTime startDate;
  final DateTime endDate;

  double get previousResultSeconds => previousResultCentiseconds / 100;
  double get currentResultSeconds => currentResultCentiseconds / 100;

  factory TrainingAnalysis.fromFirestore(
      String id, Map<String, dynamic> data) {
    return TrainingAnalysis(
      id: id,
      athleteId: data['athleteId'] as String? ?? '',
      previousCompetitionId: data['previousCompetitionId'] as String? ?? '',
      currentCompetitionId: data['currentCompetitionId'] as String? ?? '',
      previousResultCentiseconds:
          (data['previousResultCentiseconds'] as num?)?.toInt() ?? 0,
      currentResultCentiseconds:
          (data['currentResultCentiseconds'] as num?)?.toInt() ?? 0,
      distanceMeters: (data['distanceMeters'] as num?)?.toInt() ?? 0,
      strokeKey: data['strokeKey'] as String? ?? '',
      workoutsCount: (data['workoutsCount'] as num?)?.toInt() ?? 0,
      improvementInSeconds:
          (data['improvementInSeconds'] as num?)?.toDouble() ?? 0,
      progressPercent: (data['progressPercent'] as num?)?.toDouble() ?? 0,
      averageWorkoutEfficiency:
          (data['averageWorkoutEfficiency'] as num?)?.toDouble() ?? 0,
      efficiencyLevel: data['efficiencyLevel'] as String? ?? '',
      startDate: _parseDate(data['startDate']),
      endDate: _parseDate(data['endDate']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'athleteId': athleteId,
        'previousCompetitionId': previousCompetitionId,
        'currentCompetitionId': currentCompetitionId,
        'previousResultCentiseconds': previousResultCentiseconds,
        'currentResultCentiseconds': currentResultCentiseconds,
        'distanceMeters': distanceMeters,
        'strokeKey': strokeKey,
        'workoutsCount': workoutsCount,
        'improvementInSeconds': improvementInSeconds,
        'progressPercent': progressPercent,
        'averageWorkoutEfficiency': averageWorkoutEfficiency,
        'efficiencyLevel': efficiencyLevel,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'createdAt': FieldValue.serverTimestamp(),
      };

  static DateTime _parseDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return DateTime.now();
  }
}
