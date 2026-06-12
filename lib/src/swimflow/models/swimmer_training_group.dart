abstract final class SwimmerTrainingGroup {
  static const sprint = 'sprint';
  static const distance = 'distance';
  static const mixed = 'mixed';

  static const List<String> orderedIds = [sprint, distance, mixed];

  static String labelRu(String? id) {
    switch (id) {
      case sprint:
        return 'Спринт';
      case distance:
        return 'Стайеры';
      case mixed:
        return 'Смешанная';
      default:
        return 'Не указана';
    }
  }

  static bool isValid(String? id) => id != null && orderedIds.contains(id);
}
