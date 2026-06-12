import 'package:cloud_firestore/cloud_firestore.dart';

class CompetitionSwim {
  const CompetitionSwim({
    required this.id,
    required this.eventDate,
    required this.distanceMeters,
    required this.strokeKey,
    required this.timeCentiseconds,
    required this.poolLengthMeters,
    required this.city,
    this.competitionName,
  });

  final String id;
  final DateTime eventDate;
  final int distanceMeters;
  final String strokeKey;
  final int timeCentiseconds;
  final int poolLengthMeters;
  final String city;
  final String? competitionName;

  static CompetitionSwim fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data()!;
    final ts = m['eventDate'];
    DateTime eventDate;
    if (ts is Timestamp) {
      eventDate = ts.toDate();
    } else {
      eventDate = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return CompetitionSwim(
      id: d.id,
      eventDate: eventDate,
      distanceMeters: (m['distanceMeters'] as num?)?.toInt() ?? 0,
      strokeKey: m['strokeKey'] as String? ?? 'free',
      timeCentiseconds: (m['timeCentiseconds'] as num?)?.toInt() ?? 0,
      poolLengthMeters: (m['poolLengthMeters'] as num?)?.toInt() ?? 25,
      city: m['city'] as String? ?? '',
      competitionName: m['competitionName'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventDate': Timestamp.fromDate(eventDate),
      'distanceMeters': distanceMeters,
      'strokeKey': strokeKey,
      'timeCentiseconds': timeCentiseconds,
      'poolLengthMeters': poolLengthMeters,
      'city': city,
      if (competitionName != null && competitionName!.isNotEmpty) 'competitionName': competitionName,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

const competitionDistancesMetersByStroke = <String, List<int>>{
  'free': [50, 100, 200, 400, 800, 1500],
  'back': [50, 100, 200],
  'breast': [50, 100, 200],
  'fly': [50, 100, 200],
  'im': [100, 200, 400],
};

const competitionStrokeLabelsRu = <String, String>{
  'free': 'Вольный стиль',
  'breast': 'Брасс',
  'back': 'На спине',
  'fly': 'Баттерфляй',
  'im': 'Комплекс',
};
