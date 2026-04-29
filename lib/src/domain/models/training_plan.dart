class TrainingPlan {
  final String id;
  final String coachId;
  final String athleteId;
  final String title;
  final double distanceMeters;
  final String targetTime;
  final DateTime? createdAt;

  const TrainingPlan({
    required this.id,
    required this.coachId,
    required this.athleteId,
    required this.title,
    required this.distanceMeters,
    required this.targetTime,
    required this.createdAt,
  });

  factory TrainingPlan.fromMap(String id, Map<String, dynamic> map) {
    return TrainingPlan(
      id: id,
      coachId: map['coachId'] as String? ?? '',
      athleteId: map['athleteId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0,
      targetTime: map['targetTime'] as String? ?? '',
      createdAt: (map['createdAt'] as dynamic)?.toDate(),
    );
  }
}
