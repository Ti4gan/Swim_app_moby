class CoachAthleteReport {
  final String athleteId;
  final String athleteName;
  final int plannedCount;
  final int completedCount;
  final double completionPercent;
  final double plannedDistanceMeters;
  final double completedDistanceMeters;

  const CoachAthleteReport({
    required this.athleteId,
    required this.athleteName,
    required this.plannedCount,
    required this.completedCount,
    required this.completionPercent,
    required this.plannedDistanceMeters,
    required this.completedDistanceMeters,
  });
}
