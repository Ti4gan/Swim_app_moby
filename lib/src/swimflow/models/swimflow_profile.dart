import 'app_user_role.dart';
import 'coach_verification_status.dart';
import 'swimflow_sport_rank.dart';

class SwimflowProfile {
  const SwimflowProfile({
    required this.displayName,
    required this.sportRankId,
    required this.city,
    required this.avatarPreset,
    required this.avatarUrl,
    required this.email,
    this.role = AppUserRole.swimmer,
    this.coachId,
    this.coachVerificationStatus,
    this.linkedCoachDisplayName,
  });

  final String displayName;
  final String sportRankId;
  final String city;
  final String avatarPreset;
  final String avatarUrl;
  final String email;
  final String role;
  final String? coachId;
  final String? coachVerificationStatus;
  final String? linkedCoachDisplayName;

  String get subtitle {
    if (role == AppUserRole.coach) {
      if (city.trim().isEmpty) return 'Тренер';
      return 'Тренер, $city';
    }
    final rank = SwimflowSportRank.labelRu(sportRankId);
    if (city.trim().isEmpty) return rank;
    return '$rank, $city';
  }

  bool get needsRequiredFields {
    if (role == AppUserRole.coach) return false;
    return displayName.trim().isEmpty || sportRankId.trim().isEmpty;
  }

  bool get coachMustPassVerification {
    if (!CoachVerificationConfig.enabled) return false;
    if (role != AppUserRole.coach) return false;
    final s = coachVerificationStatus;
    return s != CoachVerificationStatus.approved;
  }

  bool get needsCoachLink =>
      role == AppUserRole.swimmer && (coachId == null || coachId!.trim().isEmpty);

  factory SwimflowProfile.fromUserDoc(Map<String, dynamic> m, {String email = ''}) {
    return SwimflowProfile(
      displayName: m['displayName'] as String? ?? '',
      sportRankId: m['sportRank'] as String? ?? '',
      city: m['city'] as String? ?? '',
      avatarPreset: m['avatarPreset'] as String? ?? '',
      avatarUrl: m['avatarUrl'] as String? ?? '',
      email: m['email'] as String? ?? email,
      role: m['role'] as String? ?? AppUserRole.swimmer,
      coachId: m['coachId'] as String?,
      coachVerificationStatus: m['coachVerificationStatus'] as String?,
      linkedCoachDisplayName: m['linkedCoachDisplayName'] as String?,
    );
  }
}
