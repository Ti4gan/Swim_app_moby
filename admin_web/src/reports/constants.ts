export const COL = {
  users: 'users',
  coachRegistrationRequests: 'coach_registration_requests',
  catalogExercises: 'catalog_exercises',
  rankNorms: 'rank_norms',
  coachInvites: 'coach_invites',
  workouts: 'workouts',
  competitionSwims: 'competition_swims',
  performanceGoals: 'performance_goal',
  athleteDossiers: 'athleteDossiers',
  workoutTemplates: 'workout_templates',
} as const;

export const RANK_IDS = [
  'master_of_sport',
  'candidate_master',
  'first_adult',
  'second_adult',
  'third_adult',
  'first_youth',
  'second_youth',
  'third_youth',
  'no_rank',
];

export const RANK_LABELS: Record<string, string> = {
  master_of_sport: 'Мастер спорта',
  candidate_master: 'Кандидат в мастера спорта',
  first_adult: 'I взрослый разряд',
  second_adult: 'II взрослый разряд',
  third_adult: 'III взрослый разряд',
  first_youth: 'I юношеский разряд',
  second_youth: 'II юношеский разряд',
  third_youth: 'III юношеский разряд',
  no_rank: 'Без разряда',
};

export const ROLE_LABELS: Record<string, string> = {
  swimmer: 'Пловец',
  coach: 'Тренер',
  admin: 'Администратор',
};

export function roleLabel(role: string): string {
  return ROLE_LABELS[role] ?? (role || '—');
}

export const STROKE_LABELS: Record<string, string> = {
  free: 'Вольный стиль',
  breast: 'Брасс',
  back: 'На спине',
  fly: 'Баттерфляй',
  im: 'Комплекс',
};

export const MOOD_LABELS = ['Плохо', 'Так себе', 'Отлично', 'Супер', 'Восторг'];

export const PHYSICAL_LABELS: Record<string, string> = {
  tired: 'Уставший',
  normal: 'Нормально',
  energy: 'Энергичный',
};

export type ReportTypeId = 'athlete_goals_comparison' | 'coaches_effectiveness';

export type ReportDef = {
  id: ReportTypeId;
  title: string;
  hint: string;
};

export const REPORT_DEFS: ReportDef[] = [
  {
    id: 'athlete_goals_comparison',
    title: 'Желаемый и фактический результат',
    hint:
      'Сравнение целей тренера с лучшими результатами на соревнованиях и сводка тренировочного процесса по выбранному спортсмену',
  },
  {
    id: 'coaches_effectiveness',
    title: 'Эффективность тренеров',
    hint: 'Перечень тренеров, закреплённые пловцы, объём тренировок за период и выполнение целей по группе',
  },
];
