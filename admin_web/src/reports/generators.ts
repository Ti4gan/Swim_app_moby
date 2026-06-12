import type { Firestore } from 'firebase/firestore';
import type { ReportTypeId } from './constants';
import { strokeLabel } from './format';
import {
  bestCompetitionForGoal,
  loadCompetitionsForAthletes,
  loadPerformanceGoalsForAthlete,
  loadWorkoutsForAthletes,
} from './data';
import {
  formatCentiseconds,
  formatDateRu,
  formatDateTimeRu,
  formatMeters,
} from './format';
import type { ReportBuildContext, ReportSheet } from './types';

function metaRows(
  ctx: ReportBuildContext,
  extra?: { label: string; value: string }[],
): ReportSheet['meta'] {
  const base = [
    { label: 'Сформировано', value: formatDateTimeRu(ctx.generatedAt) },
    { label: 'Период с', value: ctx.filters.dateFrom ? formatDateRu(ctx.filters.dateFrom) : 'не задан' },
    { label: 'Период по', value: ctx.filters.dateTo ? formatDateRu(ctx.filters.dateTo) : 'не задан' },
  ];
  return extra ? [...base, ...extra] : base;
}

function gapCentiseconds(best: number, target: number): number {
  if (best <= 0) return 0;
  return Math.max(0, best - target);
}

async function buildAthleteGoalsComparison(
  db: Firestore,
  ctx: ReportBuildContext,
): Promise<ReportSheet[]> {
  const athleteId = ctx.filters.athleteId;
  const athlete = ctx.users.find((u) => u.id === athleteId);
  if (!athlete) return [];

  const goals = await loadPerformanceGoalsForAthlete(db, athleteId);
  const comps = await loadCompetitionsForAthletes(db, ctx.users, [athleteId], {
    ...ctx.filters,
    dateFrom: null,
    dateTo: null,
  });
  const compsInPeriod = comps.filter((c) =>
    inPeriod(c.eventDate, ctx.filters.dateFrom, ctx.filters.dateTo),
  );
  const workouts = await loadWorkoutsForAthletes(db, ctx.users, [athleteId], ctx.filters);

  const comparisonRows: (string | number)[][] = [];
  for (const g of goals) {
    const bestAll = bestCompetitionForGoal(comps, g, false, null, null);
    const bestPeriod = bestCompetitionForGoal(comps, g, true, ctx.filters.dateFrom, ctx.filters.dateTo);
    const bestCs = bestAll?.timeCentiseconds ?? 0;
    const achieved = bestCs > 0 && bestCs <= g.targetTimeCentiseconds;
    const gap = gapCentiseconds(bestCs, g.targetTimeCentiseconds);
    comparisonRows.push([
      strokeLabel(g.strokeKey),
      g.distanceMeters,
      g.poolLengthMeters,
      formatCentiseconds(g.targetTimeCentiseconds),
      bestAll ? formatCentiseconds(bestAll.timeCentiseconds) : '—',
      bestPeriod ? formatCentiseconds(bestPeriod.timeCentiseconds) : '—',
      bestCs > 0 ? formatCentiseconds(gap) : '—',
      achieved ? 'Да' : 'Нет',
      compsInPeriod.filter(
        (c) =>
          c.strokeKey === g.strokeKey &&
          c.distanceMeters === g.distanceMeters &&
          c.poolLengthMeters === g.poolLengthMeters,
      ).length,
    ]);
  }

  const totalM = workouts.reduce((s, w) => s + w.distanceMeters, 0);
  const athleteMeta = [
    { label: 'Спортсмен', value: athlete.displayName || athlete.email || athleteId },
    { label: 'Тренер', value: athlete.coachName || '—' },
    { label: 'Тренировок за период', value: String(workouts.length) },
    { label: 'Метры за период', value: formatMeters(totalM) },
    { label: 'Целей задано', value: String(goals.length) },
  ];

  const sheets: ReportSheet[] = [
    {
      name: 'Сравнение целей',
      title: 'Желаемый и фактический результат на дистанциях',
      headers: [
        'Стиль',
        'Дистанция, м',
        'Бассейн, м',
        'Целевое время',
        'Лучший факт (все старты)',
        'Лучший за период',
        'До цели',
        'Достигнута',
        'Стартов за период',
      ],
      meta: metaRows(ctx, athleteMeta),
      rows:
        comparisonRows.length > 0
          ? comparisonRows
          : [['—', '—', '—', '—', '—', '—', '—', '—', 'Тренер не задал целей']],
    },
    {
      name: 'Соревнования',
      title: 'Соревновательные заплывы за период',
      headers: ['Дата', 'Соревнование', 'Дистанция, м', 'Стиль', 'Время', 'Бассейн, м', 'Город'],
      meta: metaRows(ctx, athleteMeta),
      rows: compsInPeriod.map((r) => [
        formatDateRu(r.eventDate),
        r.competitionName || '—',
        r.distanceMeters,
        strokeLabel(r.strokeKey),
        formatCentiseconds(r.timeCentiseconds),
        r.poolLengthMeters,
        r.city,
      ]),
    },
    {
      name: 'Тренировки',
      title: 'Тренировочный процесс за период',
      headers: ['Дата', 'Название', 'Метры', 'Минуты', 'Стиль', 'Тренер', 'Темп/100'],
      meta: metaRows(ctx, athleteMeta),
      rows: workouts.map((w) => [
        formatDateTimeRu(w.scheduledAt),
        w.title,
        Math.round(w.distanceMeters),
        w.durationMinutes,
        w.strokeLabel,
        w.coachName || '—',
        w.pacePer100,
      ]),
    },
  ];
  return sheets;
}

function inPeriod(d: Date | null, from: Date | null, to: Date | null): boolean {
  if (!from && !to) return true;
  if (!d) return false;
  const day = new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime();
  if (from) {
    const f = new Date(from.getFullYear(), from.getMonth(), from.getDate()).getTime();
    if (day < f) return false;
  }
  if (to) {
    const t = new Date(to.getFullYear(), to.getMonth(), to.getDate()).getTime();
    if (day > t) return false;
  }
  return true;
}

async function buildCoachesEffectiveness(
  db: Firestore,
  ctx: ReportBuildContext,
): Promise<ReportSheet[]> {
  let coaches = ctx.users.filter((u) => u.role === 'coach' && u.displayName);
  if (ctx.filters.coachId) {
    coaches = coaches.filter((c) => c.id === ctx.filters.coachId);
  }
  coaches.sort((a, b) => a.displayName.localeCompare(b.displayName, 'ru'));

  const rosterRows: (string | number)[][] = [];
  const assignRows: (string | number)[][] = [];

  for (const coach of coaches) {
    const swimmers = ctx.users.filter((u) => u.role === 'swimmer' && u.coachId === coach.id);
    swimmers.sort((a, b) => a.displayName.localeCompare(b.displayName, 'ru'));

    const athleteIds = swimmers.map((s) => s.id);
    const workouts =
      athleteIds.length > 0
        ? await loadWorkoutsForAthletes(db, ctx.users, athleteIds, ctx.filters)
        : [];

    let goalsTotal = 0;
    let goalsAchieved = 0;
    for (const s of swimmers) {
      const goals = await loadPerformanceGoalsForAthlete(db, s.id);
      goalsTotal += goals.length;
      const comps = await loadCompetitionsForAthletes(db, ctx.users, [s.id], {
        ...ctx.filters,
        dateFrom: null,
        dateTo: null,
      });
      for (const g of goals) {
        const best = bestCompetitionForGoal(comps, g, false, null, null);
        if (best && best.timeCentiseconds <= g.targetTimeCentiseconds) goalsAchieved += 1;
      }
    }

    const totalM = workouts.reduce((sum, w) => sum + w.distanceMeters, 0);
    rosterRows.push([
      coach.displayName,
      coach.email,
      swimmers.length,
      workouts.length,
      Math.round(totalM),
      swimmers.length ? (totalM / swimmers.length / 1000).toFixed(2) : '0',
      swimmers.length ? (workouts.length / swimmers.length).toFixed(1) : '0',
      goalsTotal,
      goalsAchieved,
    ]);

    for (const s of swimmers) {
      const swWorkouts = workouts.filter((w) => w.athleteUid === s.id);
      const swM = swWorkouts.reduce((sum, w) => sum + w.distanceMeters, 0);
      assignRows.push([
        coach.displayName,
        s.displayName,
        s.email,
        s.city || '—',
        s.sportRank || '—',
        swWorkouts.length,
        Math.round(swM),
      ]);
    }
  }

  return [
    {
      name: 'Сводка тренеров',
      title: 'Эффективность ведения тренировочного процесса',
      headers: [
        'Тренер',
        'Почта',
        'Пловцов',
        'Тренировок за период',
        'Метры за период',
        'км на пловца',
        'Тренировок на пловца',
        'Целей задано',
        'Целей достигнуто',
      ],
      meta: metaRows(ctx),
      rows: rosterRows,
    },
    {
      name: 'Закрепление',
      title: 'Тренеры и закреплённые пловцы',
      headers: ['Тренер', 'Пловец', 'Почта', 'Город', 'Разряд', 'Тренировок', 'Метры'],
      meta: metaRows(ctx),
      rows: assignRows,
    },
  ];
}

export type BuildProgress = (msg: string) => void;

export async function buildReportSheets(
  db: Firestore,
  reportId: ReportTypeId,
  ctx: ReportBuildContext,
  onProgress?: BuildProgress,
): Promise<ReportSheet[]> {
  onProgress?.('Загрузка данных…');
  if (reportId === 'athlete_goals_comparison') {
    return buildAthleteGoalsComparison(db, ctx);
  }
  if (reportId === 'coaches_effectiveness') {
    return buildCoachesEffectiveness(db, ctx);
  }
  return [];
}
