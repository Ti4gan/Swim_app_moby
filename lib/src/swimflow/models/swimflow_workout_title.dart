abstract final class SwimflowWorkoutTitle {
  static String generate(DateTime atLocal, double metersM) {
    final m = metersM.round();
    final h = atLocal.hour;

    String periodM;
    String periodF;
    if (h >= 5 && h < 10) {
      periodM = 'Утренний';
      periodF = 'Утренняя';
    } else if (h >= 10 && h < 13) {
      periodM = 'Полуденный';
      periodF = 'Полуденная';
    } else if (h >= 13 && h < 17) {
      periodM = 'Дневной';
      periodF = 'Дневная';
    } else if (h >= 17 && h < 21) {
      periodM = 'Вечерний';
      periodF = 'Вечерняя';
    } else if (h >= 21 || h < 1) {
      periodM = 'Поздний';
      periodF = 'Поздняя';
    } else {
      periodM = 'Ночной';
      periodF = 'Ночная';
    }

    if (m < 150) {
      return '$periodF короткая сессия';
    }
    if (m < 350) {
      return '$periodF разминка';
    }
    if (m < 550) {
      return '$periodF лёгкая тренировка';
    }
    if (m < 900) {
      return '$periodF техническая тренировка';
    }
    if (m < 1400) {
      return '$periodM средний заплыв';
    }
    if (m < 2200) {
      return '$periodM заплыв';
    }
    if (m < 3200) {
      return '$periodM длинный заплыв';
    }
    if (m < 4500) {
      return '$periodM объёмная тренировка';
    }
    if (m < 6000) {
      return '$periodM большой объём';
    }
    if (m < 8000) {
      return '$periodM мини-марафон';
    }
    return '$periodM марафонский заплыв';
  }
}
