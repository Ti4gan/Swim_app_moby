class AthleteProfile {
  final String id;
  final String coachId;
  final String fullName;
  final String entryCode;

  const AthleteProfile({
    required this.id,
    required this.coachId,
    required this.fullName,
    required this.entryCode,
  });

  factory AthleteProfile.fromMap(String id, Map<String, dynamic> map) {
    return AthleteProfile(
      id: id,
      coachId: map['coachId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      entryCode: map['entryCode'] as String? ?? '',
    );
  }
}
