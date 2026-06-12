import { collection, getDocs, type Firestore } from 'firebase/firestore';
import { COL } from './constants';
import {
  formatDateTimeRu,
  inDateRange,
  moodLabel,
  physicalLabel,
  rankLabel,
  tsToDate,
} from './format';
import {
  listSubtitleFromWorkout,
  pacePer100,
  strokeLabelFromMeta,
} from './derived';
import type {
  AdminUserRow,
  CompetitionRow,
  PerformanceGoalRow,
  ReportFilters,
  SetRow,
  WorkoutRow,
} from './types';

function goalDocId(strokeKey: string, distanceMeters: number, poolLengthMeters: number): string {
  return `${strokeKey}_${distanceMeters}_${poolLengthMeters}`;
}

function parsePerformanceGoalDoc(
  athleteUid: string,
  docId: string,
  data: Record<string, unknown>,
): PerformanceGoalRow {
  const strokeKey = String(data.strokeKey ?? 'free');
  const distanceMeters = Number(data.distanceMeters ?? 0) || 0;
  const poolLengthMeters = Number(data.poolLengthMeters ?? 25) || 25;
  const id =
    docId === 'current' ? goalDocId(strokeKey, distanceMeters, poolLengthMeters) : docId;
  return {
    id,
    athleteUid,
    strokeKey,
    distanceMeters,
    poolLengthMeters,
    targetTimeCentiseconds: Number(data.targetTimeCentiseconds ?? 0) || 0,
    updatedAt: tsToDate(data.updatedAt),
  };
}

export async function loadPerformanceGoalsForAthlete(
  db: Firestore,
  athleteUid: string,
): Promise<PerformanceGoalRow[]> {
  const snap = await getDocs(collection(db, COL.users, athleteUid, COL.performanceGoals));
  const byId = new Map<string, PerformanceGoalRow>();
  for (const d of snap.docs) {
    const g = parsePerformanceGoalDoc(athleteUid, d.id, d.data());
    const prev = byId.get(g.id);
    if (!prev || d.id !== 'current') byId.set(g.id, g);
  }
  const goals = [...byId.values()];
  goals.sort((a, b) => {
    const sc = a.strokeKey.localeCompare(b.strokeKey);
    if (sc !== 0) return sc;
    const dc = a.distanceMeters - b.distanceMeters;
    if (dc !== 0) return dc;
    return a.poolLengthMeters - b.poolLengthMeters;
  });
  return goals;
}

export function bestCompetitionForGoal(
  comps: CompetitionRow[],
  goal: PerformanceGoalRow,
  inPeriodOnly: boolean,
  dateFrom: Date | null,
  dateTo: Date | null,
): CompetitionRow | null {
  let best: CompetitionRow | null = null;
  for (const c of comps) {
    if (c.athleteUid !== goal.athleteUid) continue;
    if (c.strokeKey !== goal.strokeKey) continue;
    if (c.distanceMeters !== goal.distanceMeters) continue;
    if (c.poolLengthMeters !== goal.poolLengthMeters) continue;
    if (c.timeCentiseconds <= 0) continue;
    if (inPeriodOnly && !inDateRange(c.eventDate, dateFrom, dateTo)) continue;
    if (!best || c.timeCentiseconds < best.timeCentiseconds) best = c;
  }
  return best;
}

export async function loadUsers(db: Firestore): Promise<AdminUserRow[]> {
  const snap = await getDocs(collection(db, COL.users));
  const nameById = new Map<string, string>();
  for (const d of snap.docs) {
    const n = String(d.data().displayName ?? '').trim();
    if (n) nameById.set(d.id, n);
  }
  const rows: AdminUserRow[] = [];
  for (const d of snap.docs) {
    const x = d.data();
    const coachId = String(x.coachId ?? '').trim();
    rows.push({
      id: d.id,
      displayName: String(x.displayName ?? '').trim(),
      email: String(x.email ?? '').trim(),
      role: String(x.role ?? '').trim(),
      city: String(x.city ?? '').trim(),
      sportRank: rankLabel(String(x.sportRank ?? '').trim()),
      coachId,
      coachName: coachId ? (nameById.get(coachId) ?? '') : '',
      totalWorkouts: 0,
      totalDistanceMeters: 0,
      workoutsThisMonth: 0,
      phone: String(x.presetPhone ?? x.phone ?? '').trim(),
      trainingGroup: String(x.trainingGroup ?? '').trim(),
      coachVerificationStatus: String(x.coachVerificationStatus ?? '').trim(),
      raw: x,
    });
  }
  rows.sort((a, b) => a.displayName.localeCompare(b.displayName, 'ru'));
  return rows;
}

export function swimmersForCoach(users: AdminUserRow[], coachId: string): AdminUserRow[] {
  return users.filter((u) => u.role === 'swimmer' && u.coachId === coachId);
}

export function resolveAthleteIds(
  users: AdminUserRow[],
  coachId: string,
  selected: string[],
): string[] {
  if (selected.length > 0) return selected;
  return swimmersForCoach(users, coachId).map((u) => u.id);
}

export async function loadCoachRequests(db: Firestore): Promise<Record<string, unknown>[]> {
  const snap = await getDocs(collection(db, COL.coachRegistrationRequests));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function loadCatalog(db: Firestore): Promise<Record<string, unknown>[]> {
  const snap = await getDocs(collection(db, COL.catalogExercises));
  const items = snap.docs.map((d) => ({ id: d.id, ...d.data() } as Record<string, unknown> & { id: string }));
  return items.sort((a, b) => Number(a.sortOrder ?? 0) - Number(b.sortOrder ?? 0));
}

export async function loadRankNorms(db: Firestore): Promise<Record<string, unknown>[]> {
  const snap = await getDocs(collection(db, COL.rankNorms));
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

export async function loadCoachInvites(db: Firestore): Promise<Record<string, unknown>[]> {
  const snap = await getDocs(collection(db, COL.coachInvites));
  return snap.docs.map((d) => ({ code: d.id, ...d.data() }));
}

function parseWorkoutDoc(
  athleteUid: string,
  athleteName: string,
  coachNameById: Map<string, string>,
  workoutId: string,
  data: Record<string, unknown>,
): WorkoutRow {
  const coachId = String(data.coachId ?? '').trim();
  const scheduledAt = tsToDate(data.scheduledAt);
  const distanceMeters = Number(data.distanceMeters ?? 0) || 0;
  const durationSeconds = Number(data.durationSeconds ?? 0) || 0;
  const storedMinutes = Number(data.durationMinutes ?? 0) || 0;
  const durationMinutes =
    storedMinutes > 0 ? storedMinutes : durationSeconds > 0 ? Math.ceil(durationSeconds / 60) : 0;
  const recordMeta = (data.recordMeta as Record<string, unknown> | undefined) ?? null;
  const storedPace = String(data.pacePer100 ?? '').trim();
  const pace =
    storedPace && storedPace !== '—' ? storedPace : pacePer100(distanceMeters, durationSeconds);
  const storedStroke = String(data.strokeLabel ?? '').trim();
  const stroke = storedStroke || strokeLabelFromMeta(storedStroke, recordMeta);
  const storedSubtitle = String(data.listSubtitle ?? '').trim();
  const listSubtitle =
    storedSubtitle ||
    listSubtitleFromWorkout(storedSubtitle, scheduledAt, distanceMeters, recordMeta);
  return {
    id: workoutId,
    athleteUid,
    athleteName,
    coachId,
    coachName: coachId ? (coachNameById.get(coachId) ?? '') : '',
    title: String(data.title ?? '').trim(),
    scheduledAt,
    distanceMeters,
    durationMinutes,
    durationSeconds,
    strokeLabel: stroke,
    poolName: String(data.poolName ?? '').trim(),
    calories: Number(data.calories ?? 0) || 0,
    pacePer100: pace,
    listSubtitle,
    recordMeta,
    raw: data,
  };
}

export async function loadWorkoutsForAthletes(
  db: Firestore,
  users: AdminUserRow[],
  athleteIds: string[],
  filters: ReportFilters,
): Promise<WorkoutRow[]> {
  const userById = new Map(users.map((u) => [u.id, u]));
  const coachNameById = new Map(
    users.filter((u) => u.role === 'coach').map((u) => [u.id, u.displayName]),
  );
  const out: WorkoutRow[] = [];
  for (const uid of athleteIds) {
    const u = userById.get(uid);
    const snap = await getDocs(collection(db, COL.users, uid, COL.workouts));
    for (const d of snap.docs) {
      const row = parseWorkoutDoc(uid, u?.displayName ?? '', coachNameById, d.id, d.data());
      if (!inDateRange(row.scheduledAt, filters.dateFrom, filters.dateTo)) continue;
      out.push(row);
    }
  }
  out.sort((a, b) => (b.scheduledAt?.getTime() ?? 0) - (a.scheduledAt?.getTime() ?? 0));
  return out;
}

export async function loadAllWorkouts(
  db: Firestore,
  users: AdminUserRow[],
  filters: ReportFilters,
): Promise<WorkoutRow[]> {
  const swimmers = users.filter((u) => u.role === 'swimmer');
  return loadWorkoutsForAthletes(
    db,
    users,
    swimmers.map((s) => s.id),
    filters,
  );
}

export function extractSetRows(workouts: WorkoutRow[]): SetRow[] {
  const out: SetRow[] = [];
  for (const w of workouts) {
    const sets = (w.recordMeta?.sets as unknown[] | undefined) ?? [];
    sets.forEach((raw, i) => {
      if (!raw || typeof raw !== 'object') return;
      const s = raw as Record<string, unknown>;
      const reps = Number(s.reps ?? 1) || 1;
      const dist = Number(s.distanceMeters ?? s.intervalMeters ?? 0) || 0;
      const strokeKey = String(s.strokeKey ?? '').trim();
      const intensity = Number(s.intensityIndex ?? s.intensity ?? 0) || 0;
      out.push({
        workoutId: w.id,
        athleteUid: w.athleteUid,
        athleteName: w.athleteName,
        workoutTitle: w.title,
        scheduledAt: w.scheduledAt,
        setIndex: i + 1,
        reps,
        distanceMeters: dist,
        strokeKey,
        intensityIndex: intensity,
        totalMeters: reps * dist,
      });
    });
  }
  return out;
}

export async function loadCompetitionsForAthletes(
  db: Firestore,
  users: AdminUserRow[],
  athleteIds: string[],
  filters: ReportFilters,
): Promise<CompetitionRow[]> {
  const userById = new Map(users.map((u) => [u.id, u]));
  const out: CompetitionRow[] = [];
  for (const uid of athleteIds) {
    const u = userById.get(uid);
    const snap = await getDocs(collection(db, COL.users, uid, COL.competitionSwims));
    for (const d of snap.docs) {
      const x = d.data();
      const eventDate = tsToDate(x.eventDate);
      if (!inDateRange(eventDate, filters.dateFrom, filters.dateTo)) continue;
      out.push({
        id: d.id,
        athleteUid: uid,
        athleteName: u?.displayName ?? '',
        eventDate,
        distanceMeters: Number(x.distanceMeters ?? 0) || 0,
        strokeKey: String(x.strokeKey ?? ''),
        timeCentiseconds: Number(x.timeCentiseconds ?? 0) || 0,
        poolLengthMeters: Number(x.poolLengthMeters ?? 25) || 25,
        city: String(x.city ?? '').trim(),
        competitionName: String(x.competitionName ?? '').trim(),
      });
    }
  }
  out.sort((a, b) => (b.eventDate?.getTime() ?? 0) - (a.eventDate?.getTime() ?? 0));
  return out;
}

export async function loadAllDossiers(
  db: Firestore,
  coachUsers: AdminUserRow[],
  athleteFilter: string[],
): Promise<Record<string, unknown>[]> {
  const out: Record<string, unknown>[] = [];
  const filterSet = athleteFilter.length > 0 ? new Set(athleteFilter) : null;
  for (const coach of coachUsers) {
    const snap = await getDocs(collection(db, COL.users, coach.id, COL.athleteDossiers));
    for (const d of snap.docs) {
      if (filterSet && !filterSet.has(d.id)) continue;
      out.push({ coachId: coach.id, coachName: coach.displayName, athleteUid: d.id, ...d.data() });
    }
  }
  return out;
}

export async function loadWorkoutTemplates(
  db: Firestore,
  coachUsers: AdminUserRow[],
): Promise<Record<string, unknown>[]> {
  const out: Record<string, unknown>[] = [];
  for (const coach of coachUsers) {
    const snap = await getDocs(collection(db, COL.users, coach.id, COL.workoutTemplates));
    for (const d of snap.docs) {
      out.push({ coachId: coach.id, coachName: coach.displayName, templateId: d.id, ...d.data() });
    }
  }
  return out;
}

export type DbCounts = {
  users: number;
  swimmers: number;
  coaches: number;
  admins: number;
  coachRequests: number;
  catalog: number;
  rankNorms: number;
  invites: number;
  workouts: number;
  competitions: number;
  dossiers: number;
  templates: number;
};

export async function countDatabase(
  db: Firestore,
  users: AdminUserRow[],
): Promise<DbCounts> {
  const swimmers = users.filter((u) => u.role === 'swimmer');
  const coaches = users.filter((u) => u.role === 'coach');
  const admins = users.filter((u) => u.role === 'admin');
  const [req, cat, norms, inv] = await Promise.all([
    getDocs(collection(db, COL.coachRegistrationRequests)),
    getDocs(collection(db, COL.catalogExercises)),
    getDocs(collection(db, COL.rankNorms)),
    getDocs(collection(db, COL.coachInvites)),
  ]);
  let workouts = 0;
  let competitions = 0;
  let dossiers = 0;
  let templates = 0;
  for (const s of swimmers) {
    const [w, c] = await Promise.all([
      getDocs(collection(db, COL.users, s.id, COL.workouts)),
      getDocs(collection(db, COL.users, s.id, COL.competitionSwims)),
    ]);
    workouts += w.size;
    competitions += c.size;
  }
  for (const coach of coaches) {
    const [d, t] = await Promise.all([
      getDocs(collection(db, COL.users, coach.id, COL.athleteDossiers)),
      getDocs(collection(db, COL.users, coach.id, COL.workoutTemplates)),
    ]);
    dossiers += d.size;
    templates += t.size;
  }
  return {
    users: users.length,
    swimmers: swimmers.length,
    coaches: coaches.length,
    admins: admins.length,
    coachRequests: req.size,
    catalog: cat.size,
    rankNorms: norms.size,
    invites: inv.size,
    workouts,
    competitions,
    dossiers,
    templates,
  };
}

export function wellbeingRow(w: WorkoutRow): (string | number)[] {
  const meta = w.recordMeta ?? {};
  const saved = meta.wellbeingSaved === true || meta.wellbeingSavedAt != null;
  const byCoach = meta.enteredByCoach === true;
  return [
    w.athleteName,
    w.title,
    formatDateTimeRu(w.scheduledAt),
    moodLabel(meta.mood),
    Number(meta.fatigue ?? '') || '—',
    physicalLabel(meta.physicalState),
    saved ? 'Да' : 'Нет',
    byCoach ? 'Тренер' : 'Пловец',
  ];
}
