import 'package:cloud_firestore/cloud_firestore.dart';

class LinkedAthlete {
  const LinkedAthlete({
    required this.uid,
    required this.displayName,
    required this.avatarUrl,
    required this.sportRankId,
    required this.city,
    required this.coachInviteLabel,
    required this.presetBirthYear,
    required this.presetCity,
    required this.presetPhone,
    required this.presetNotes,
    required this.avatarPreset,
    required this.trainingGroup,
  });

  final String uid;
  final String displayName;
  final String avatarUrl;
  final String avatarPreset;
  final String sportRankId;
  final String city;
  final String coachInviteLabel;
  final int? presetBirthYear;
  final String presetCity;
  final String presetPhone;
  final String presetNotes;
  final String trainingGroup;

  factory LinkedAthlete.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    return LinkedAthlete(
      uid: doc.id,
      displayName: m['displayName'] as String? ?? '',
      avatarUrl: m['avatarUrl'] as String? ?? '',
      sportRankId: m['sportRank'] as String? ?? '',
      city: m['city'] as String? ?? '',
      coachInviteLabel: m['coachInviteLabel'] as String? ?? '',
      presetBirthYear: (m['presetBirthYear'] as num?)?.toInt(),
      presetCity: m['presetCity'] as String? ?? '',
      presetPhone: m['presetPhone'] as String? ?? '',
      presetNotes: m['presetNotes'] as String? ?? '',
      avatarPreset: m['avatarPreset'] as String? ?? '',
      trainingGroup: m['trainingGroup'] as String? ?? '',
    );
  }

  int? get ageYears {
    if (presetBirthYear == null) return null;
    return DateTime.now().year - presetBirthYear!;
  }
}
