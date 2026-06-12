export type ReportSheet = {
  name: string;
  title: string;
  headers: string[];
  rows: (string | number)[][];
  meta?: { label: string; value: string }[];
};

export type AdminUserRow = {
  id: string;
  displayName: string;
  email: string;
  role: string;
  city: string;
  sportRank: string;
  coachId: string;
  coachName: string;
  totalWorkouts: number;
  totalDistanceMeters: number;
  workoutsThisMonth: number;
  phone: string;
  trainingGroup: string;
  coachVerificationStatus: string;
  raw: Record<string, unknown>;
};

export type WorkoutRow = {
  id: string;
  athleteUid: string;
  athleteName: string;
  coachId: string;
  coachName: string;
  title: string;
  scheduledAt: Date | null;
  distanceMeters: number;
  durationMinutes: number;
  durationSeconds: number;
  strokeLabel: string;
  poolName: string;
  calories: number;
  pacePer100: string;
  listSubtitle: string;
  recordMeta: Record<string, unknown> | null;
  raw: Record<string, unknown>;
};

export type SetRow = {
  workoutId: string;
  athleteUid: string;
  athleteName: string;
  workoutTitle: string;
  scheduledAt: Date | null;
  setIndex: number;
  reps: number;
  distanceMeters: number;
  strokeKey: string;
  intensityIndex: number;
  totalMeters: number;
};

export type CompetitionRow = {
  id: string;
  athleteUid: string;
  athleteName: string;
  eventDate: Date | null;
  distanceMeters: number;
  strokeKey: string;
  timeCentiseconds: number;
  poolLengthMeters: number;
  city: string;
  competitionName: string;
};

export type PerformanceGoalRow = {
  id: string;
  athleteUid: string;
  strokeKey: string;
  distanceMeters: number;
  poolLengthMeters: number;
  targetTimeCentiseconds: number;
  updatedAt: Date | null;
};

export type ReportFilters = {
  dateFrom: Date | null;
  dateTo: Date | null;
  coachId: string;
  athleteIds: string[];
  athleteId: string;
};

export type ReportBuildContext = {
  users: AdminUserRow[];
  filters: ReportFilters;
  generatedAt: Date;
};
