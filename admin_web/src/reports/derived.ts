import type { WorkoutRow } from './types';

export type UserWorkoutStats = {
  totalWorkouts: number;
  totalDistanceMeters: number;
  workoutsThisMonth: number;
};

export function userStatsFromWorkouts(
  athleteUid: string,
  workouts: WorkoutRow[],
  now = new Date(),
): UserWorkoutStats {
  const month = now.getMonth();
  const year = now.getFullYear();
  let totalWorkouts = 0;
  let totalDistanceMeters = 0;
  let workoutsThisMonth = 0;
  for (const w of workouts) {
    if (w.athleteUid !== athleteUid) continue;
    totalWorkouts++;
    totalDistanceMeters += w.distanceMeters;
    const at = w.scheduledAt;
    if (at && at.getMonth() === month && at.getFullYear() === year) {
      workoutsThisMonth++;
    }
  }
  return { totalWorkouts, totalDistanceMeters, workoutsThisMonth };
}

export function buildUserStatsIndex(
  workouts: WorkoutRow[],
  now = new Date(),
): Map<string, UserWorkoutStats> {
  const map = new Map<string, UserWorkoutStats>();
  for (const w of workouts) {
    const uid = w.athleteUid;
    const cur = map.get(uid) ?? { totalWorkouts: 0, totalDistanceMeters: 0, workoutsThisMonth: 0 };
    cur.totalWorkouts++;
    cur.totalDistanceMeters += w.distanceMeters;
    const at = w.scheduledAt;
    if (at && at.getMonth() === now.getMonth() && at.getFullYear() === now.getFullYear()) {
      cur.workoutsThisMonth++;
    }
    map.set(uid, cur);
  }
  return map;
}

export function catalogVolumeMeters(x: Record<string, unknown>): number {
  const legacy = Number(x.recommendedMeters ?? 0) || 0;
  const reps = Number(x.presetReps ?? 0) || 0;
  const interval = Number(x.presetIntervalMeters ?? 0) || 0;
  if (reps > 0 && interval > 0) return reps * interval;
  return legacy;
}

export function pacePer100(meters: number, sec: number): string {
  if (meters <= 0 || sec <= 0) return '—';
  const per100 = (sec / meters) * 100;
  const m = Math.floor(per100 / 60);
  const s = Math.round(per100 % 60);
  return `${m}:${String(s).padStart(2, '0')}`;
}

export function strokeLabelFromMeta(
  stored: string,
  recordMeta: Record<string, unknown> | null | undefined,
): string {
  const trimmed = stored.trim();
  const sets = recordMeta?.sets;
  if (!Array.isArray(sets) || sets.length === 0) return trimmed || 'КОМПЛЕКС';
  const keys = new Set<string>();
  for (const raw of sets) {
    if (!raw || typeof raw !== 'object') continue;
    const sk = String((raw as Record<string, unknown>).strokeKey ?? '').trim();
    if (sk) keys.add(sk);
  }
  if (keys.size >= 2) return 'КОМПЛЕКС';
  if (keys.size === 1) {
    switch ([...keys][0]) {
      case 'breast':
        return 'БРАСС';
      case 'back':
        return 'СПИНА';
      case 'fly':
        return 'БАТТЕРФЛЯЙ';
      case 'im':
        return 'КОМПЛЕКС';
      default:
        return 'КРОЛЬ';
    }
  }
  return trimmed || 'КОМПЛЕКС';
}

export function listSubtitleFromWorkout(
  stored: string,
  scheduledAt: Date | null,
  distanceMeters: number,
  recordMeta: Record<string, unknown> | null | undefined,
): string {
  const trimmed = stored.trim();
  if (trimmed === 'Запись тренера' || trimmed === 'Только что') return trimmed;
  if (recordMeta?.enteredByCoach === true) return 'Запись тренера';
  if (scheduledAt) {
    const today = new Date();
    const day = new Date(scheduledAt.getFullYear(), scheduledAt.getMonth(), scheduledAt.getDate());
    const todayDay = new Date(today.getFullYear(), today.getMonth(), today.getDate());
    if (day > todayDay) return 'Запланировано';
  }
  if (distanceMeters > 0) return `${Math.round(distanceMeters)} м`;
  return trimmed || '—';
}
