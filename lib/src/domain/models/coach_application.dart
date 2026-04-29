class CoachApplication {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String documentUrl;
  final String status;

  const CoachApplication({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.documentUrl,
    required this.status,
  });

  factory CoachApplication.fromMap(String id, Map<String, dynamic> map) {
    return CoachApplication(
      id: id,
      userId: map['userId'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      documentUrl: map['documentUrl'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
    );
  }
}
