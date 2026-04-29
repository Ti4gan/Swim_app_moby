class TrainingResult {
  final String id;
  final String athleteUserId;
  final String trainingPlanId;
  final double distanceMeters;
  final String timeValue;
  final DateTime? createdAt;

  const TrainingResult({
    required this.id,
    required this.athleteUserId,
    required this.trainingPlanId,
    required this.distanceMeters,
    required this.timeValue,
    required this.createdAt,
  });

  factory TrainingResult.fromMap(String id, Map<String, dynamic> map) {
    return TrainingResult(
      id: id,
      athleteUserId: map['athleteUserId'] as String? ?? '',
      trainingPlanId: map['trainingPlanId'] as String? ?? '',
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0,
      timeValue: map['timeValue'] as String? ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate(),
    );
  }
}
