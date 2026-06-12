import 'package:cloud_firestore/cloud_firestore.dart';

class PerformanceGoal {
  const PerformanceGoal({
    required this.id,
    required this.strokeKey,
    required this.distanceMeters,
    required this.poolLengthMeters,
    required this.targetTimeCentiseconds,
    required this.coachId,
    required this.updatedAt,
  });

  final String id;
  final String strokeKey;
  final int distanceMeters;
  final int poolLengthMeters;
  final int targetTimeCentiseconds;
  final String coachId;
  final DateTime updatedAt;

  static String docIdFor({
    required String strokeKey,
    required int distanceMeters,
    required int poolLengthMeters,
  }) =>
      '${strokeKey}_${distanceMeters}_$poolLengthMeters';

  factory PerformanceGoal.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? {};
    final ts = m['updatedAt'];
    DateTime updated = DateTime.now();
    if (ts is Timestamp) updated = ts.toDate();
    final strokeKey = m['strokeKey'] as String? ?? 'free';
    final distanceMeters = (m['distanceMeters'] as num?)?.toInt() ?? 0;
    final poolLengthMeters = (m['poolLengthMeters'] as num?)?.toInt() ?? 25;
    final id = doc.id == 'current'
        ? docIdFor(
            strokeKey: strokeKey,
            distanceMeters: distanceMeters,
            poolLengthMeters: poolLengthMeters,
          )
        : doc.id;
    return PerformanceGoal(
      id: id,
      strokeKey: strokeKey,
      distanceMeters: distanceMeters,
      poolLengthMeters: poolLengthMeters,
      targetTimeCentiseconds: (m['targetTimeCentiseconds'] as num?)?.toInt() ?? 0,
      coachId: m['coachId'] as String? ?? '',
      updatedAt: updated,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'strokeKey': strokeKey,
      'distanceMeters': distanceMeters,
      'poolLengthMeters': poolLengthMeters,
      'targetTimeCentiseconds': targetTimeCentiseconds,
      if (coachId.isNotEmpty) 'coachId': coachId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  bool matchesSwim({
    required String strokeKey,
    required int distanceMeters,
    required int poolLengthMeters,
  }) {
    return this.strokeKey == strokeKey &&
        this.distanceMeters == distanceMeters &&
        this.poolLengthMeters == poolLengthMeters;
  }

  static List<PerformanceGoal> listFromSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    final byId = <String, PerformanceGoal>{};
    for (final doc in snap.docs) {
      final g = PerformanceGoal.fromDoc(doc);
      final prev = byId[g.id];
      if (prev == null || doc.id != 'current') {
        byId[g.id] = g;
      }
    }
    final goals = byId.values.toList();
    goals.sort((a, b) {
      final sc = a.strokeKey.compareTo(b.strokeKey);
      if (sc != 0) return sc;
      final dc = a.distanceMeters.compareTo(b.distanceMeters);
      if (dc != 0) return dc;
      return a.poolLengthMeters.compareTo(b.poolLengthMeters);
    });
    return goals;
  }
}
