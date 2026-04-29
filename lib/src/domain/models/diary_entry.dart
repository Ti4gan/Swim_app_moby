class DiaryEntry {
  final String id;
  final String athleteUserId;
  final String note;
  final String mood;

  const DiaryEntry({
    required this.id,
    required this.athleteUserId,
    required this.note,
    required this.mood,
  });

  factory DiaryEntry.fromMap(String id, Map<String, dynamic> map) {
    return DiaryEntry(
      id: id,
      athleteUserId: map['athleteUserId'] as String? ?? '',
      note: map['note'] as String? ?? '',
      mood: map['mood'] as String? ?? '',
    );
  }
}
