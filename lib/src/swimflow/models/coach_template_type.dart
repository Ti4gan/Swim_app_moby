abstract final class CoachTemplateType {
  static const warmup = 'warmup';
  static const technique = 'technique';
  static const aerobic = 'aerobic';
  static const threshold = 'threshold';
  static const sprint = 'sprint';
  static const im = 'im';
  static const cooldown = 'cooldown';

  static const List<String> ordered = [
    warmup,
    technique,
    aerobic,
    threshold,
    sprint,
    im,
    cooldown,
  ];

  static String labelRu(String id) {
    switch (id) {
      case warmup:
        return 'Разминка';
      case technique:
        return 'Техника';
      case aerobic:
        return 'Аэробика';
      case threshold:
        return 'Порог';
      case sprint:
        return 'Спринт';
      case im:
        return 'Комплекс';
      case cooldown:
        return 'Заминка';
      default:
        return id;
    }
  }
}

enum CoachTemplateCatalogSort {
  nameAsc,
  metersAsc,
  metersDesc,
  type,
}

extension CoachTemplateCatalogSortX on CoachTemplateCatalogSort {
  String get labelRu {
    switch (this) {
      case CoachTemplateCatalogSort.nameAsc:
        return 'По названию';
      case CoachTemplateCatalogSort.metersAsc:
        return 'Объём ↑';
      case CoachTemplateCatalogSort.metersDesc:
        return 'Объём ↓';
      case CoachTemplateCatalogSort.type:
        return 'По типу';
    }
  }
}
