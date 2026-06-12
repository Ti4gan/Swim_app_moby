abstract final class SwimflowSportRank {
  static const masterOfSport = 'master_of_sport';
  static const candidateMaster = 'candidate_master';
  static const firstAdult = 'first_adult';
  static const secondAdult = 'second_adult';
  static const thirdAdult = 'third_adult';
  static const firstYouth = 'first_youth';
  static const secondYouth = 'second_youth';
  static const thirdYouth = 'third_youth';
  static const noRank = 'no_rank';

  static const List<String> orderedIds = [
    masterOfSport,
    candidateMaster,
    firstAdult,
    secondAdult,
    thirdAdult,
    firstYouth,
    secondYouth,
    thirdYouth,
    noRank,
  ];

  static String labelShortRu(String id) {
    switch (id) {
      case masterOfSport:
        return 'МС';
      case candidateMaster:
        return 'КМС';
      case firstAdult:
        return 'I разряд';
      case secondAdult:
        return 'II разряд';
      case thirdAdult:
        return 'III разряд';
      case firstYouth:
        return 'I юн.';
      case secondYouth:
        return 'II юн.';
      case thirdYouth:
        return 'III юн.';
      case noRank:
        return 'Без разряда';
      default:
        return labelRu(id);
    }
  }

  static String labelRu(String id) {
    switch (id) {
      case masterOfSport:
        return 'Мастер спорта';
      case candidateMaster:
        return 'Кандидат в мастера спорта';
      case firstAdult:
        return 'I взрослый разряд';
      case secondAdult:
        return 'II взрослый разряд';
      case thirdAdult:
        return 'III взрослый разряд';
      case firstYouth:
        return 'I юношеский разряд';
      case secondYouth:
        return 'II юношеский разряд';
      case thirdYouth:
        return 'III юношеский разряд';
      case noRank:
        return 'Без разряда';
      default:
        return id;
    }
  }
}
