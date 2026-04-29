import 'user_role.dart';

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final UserRole role;
  final bool approved;
  final String? athleteId;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.approved,
    this.athleteId,
  });

  factory AppUser.fromMap(String id, Map<String, dynamic> map) {
    return AppUser(
      id: id,
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == (map['role'] as String? ?? 'athlete'),
        orElse: () => UserRole.athlete,
      ),
      approved: map['approved'] as bool? ?? false,
      athleteId: map['athleteId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'approved': approved,
      'athleteId': athleteId,
    };
  }
}
