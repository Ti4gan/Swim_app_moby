import 'package:cloud_firestore/cloud_firestore.dart';

class CoachAthleteDossier {
  const CoachAthleteDossier({
    required this.athleteUid,
    required this.fullName,
    required this.birthYear,
    required this.phone,
    required this.city,
    required this.notes,
    required this.medicalNotes,
    required this.parentContact,
    required this.updatedAt,
  });

  final String athleteUid;
  final String fullName;
  final int? birthYear;
  final String phone;
  final String city;
  final String notes;
  final String medicalNotes;
  final String parentContact;
  final DateTime updatedAt;

  factory CoachAthleteDossier.empty(String athleteUid) {
    return CoachAthleteDossier(
      athleteUid: athleteUid,
      fullName: '',
      birthYear: null,
      phone: '',
      city: '',
      notes: '',
      medicalNotes: '',
      parentContact: '',
      updatedAt: DateTime.now(),
    );
  }

  factory CoachAthleteDossier.fromDoc(
    String athleteUid,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final m = doc.data() ?? {};
    final uts = m['updatedAt'];
    DateTime updated = DateTime.now();
    if (uts is Timestamp) updated = uts.toDate();
    return CoachAthleteDossier(
      athleteUid: athleteUid,
      fullName: m['fullName'] as String? ?? '',
      birthYear: (m['birthYear'] as num?)?.toInt(),
      phone: m['phone'] as String? ?? '',
      city: m['city'] as String? ?? '',
      notes: m['notes'] as String? ?? '',
      medicalNotes: m['medicalNotes'] as String? ?? '',
      parentContact: m['parentContact'] as String? ?? '',
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'birthYear': birthYear,
      'phone': phone,
      'city': city,
      'notes': notes,
      'medicalNotes': medicalNotes,
      'parentContact': parentContact,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
