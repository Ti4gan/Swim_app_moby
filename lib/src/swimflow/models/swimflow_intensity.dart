abstract final class SwimflowIntensity {
  static const List<String> labelsRu = ['Низкая', 'Средняя', 'Высокая', 'MAX'];

  static String labelRu(int index) {
    if (index < 0 || index >= labelsRu.length) return '—';
    return labelsRu[index];
  }
}
