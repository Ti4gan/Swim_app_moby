import { createRequire } from 'node:module';
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { execSync } from 'node:child_process';
import { GoogleAuth } from 'google-auth-library';
import { FirestoreRest } from './firestore_rest.ts';

const require = createRequire(import.meta.url);
const { RB_2026_RANK_NORMS, RB_2026_SOURCE } = require('../admin_web/src/rank_norms_rb_2026.ts') as {
  RB_2026_RANK_NORMS: Record<string, unknown[]>;
  RB_2026_SOURCE: string;
};

const PROJECT_ID = 'swim-app-moby';
const PASSWORD = '123456';
const CLIENT_ID = '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLIENT_SECRET = 'j9iVZfS8kkCEFUPaAeJV0sAi';

const ACCOUNTS = {
  admin: { email: 'admin@mail.ru', displayName: 'Админ Системы' },
  coach: { email: 'coach@mail.ru', displayName: 'Игорь Тренеров' },
  swimmers: [
    { email: 'user1@mail.ru', name: 'Ян Кузьмичёв', rank: 'first_youth', group: 'sprint' },
    { email: 'user2@mail.ru', name: 'Алина Морозова', rank: 'second_youth', group: 'distance' },
    { email: 'user3@mail.ru', name: 'Максим Волков', rank: 'third_youth', group: 'mixed' },
    { email: 'user4@mail.ru', name: 'София Лебедева', rank: 'third_adult', group: 'sprint' },
    { email: 'user5@mail.ru', name: 'Дмитрий Козлов', rank: 'second_adult', group: 'distance' },
    { email: 'user6@mail.ru', name: 'Полина Соколова', rank: 'first_adult', group: 'mixed' },
  ],
} as const;

const CATALOG = [
  { id: 'warm400', sortOrder: 0, title: 'Разминка вольным стилем', hint: 'Постепенное ускорение каждые 100 м', presetReps: 1, presetIntervalMeters: 400, defaultIntensityTier: 0, templateType: 'warmup', strokeKey: 'free' },
  { id: 'kick8x50', sortOrder: 1, title: 'Ноги с доской', hint: 'Отдых 15 с', presetReps: 8, presetIntervalMeters: 50, defaultIntensityTier: 1, templateType: 'technique', strokeKey: 'free' },
  { id: 'pull6x100', sortOrder: 2, title: 'Руки с лопатками', hint: 'Отдых 20 с', presetReps: 6, presetIntervalMeters: 100, defaultIntensityTier: 1, templateType: 'technique', strokeKey: 'free' },
  { id: 'aerobic10x200', sortOrder: 3, title: 'Аэробная серия кроль', hint: 'RPE 6–7', presetReps: 10, presetIntervalMeters: 200, defaultIntensityTier: 1, templateType: 'aerobic', strokeKey: 'free' },
  { id: 'threshold8x150', sortOrder: 4, title: 'Порог 8×150 м', hint: 'Отдых 20 с', presetReps: 8, presetIntervalMeters: 150, defaultIntensityTier: 2, templateType: 'threshold', strokeKey: 'free' },
  { id: 'sprint12x25', sortOrder: 5, title: 'Спринт 12×25 м', hint: 'Отдых 30–45 с', presetReps: 12, presetIntervalMeters: 25, defaultIntensityTier: 3, templateType: 'sprint', strokeKey: 'free' },
  { id: 'im400', sortOrder: 6, title: 'Комплекс IM 4×100 м', hint: 'По стилям', presetReps: 4, presetIntervalMeters: 100, defaultIntensityTier: 2, templateType: 'im', strokeKey: 'im' },
  { id: 'cool300', sortOrder: 7, title: 'Заминка вольным', hint: 'Расслабленно', presetReps: 1, presetIntervalMeters: 300, defaultIntensityTier: 0, templateType: 'cooldown', strokeKey: 'free' },
] as const;

const COMBOS = [
  ['warm400', 'aerobic10x200', 'cool300'],
  ['warm400', 'kick8x50', 'pull6x100', 'cool300'],
  ['warm400', 'threshold8x150', 'cool300'],
  ['warm400', 'sprint12x25', 'kick8x50', 'cool300'],
  ['warm400', 'im400', 'aerobic10x200', 'cool300'],
  ['warm400', 'pull6x100', 'threshold8x150', 'cool300'],
];

const STROKE_RU: Record<string, string> = { free: 'Вольный стиль', breast: 'Брасс', back: 'На спине', fly: 'Баттерфляй', im: 'Комплекс' };
const STROKE_LABEL: Record<string, string> = { free: 'КРОЛЬ', breast: 'БРАСС', back: 'СПИНА', fly: 'БАТТЕРФЛЯЙ', im: 'КОМПЛЕКС' };
const MONTHS_RU = ['', 'янв.', 'февр.', 'марта', 'апр.', 'мая', 'июня', 'июля', 'авг.', 'сент.', 'окт.', 'нояб.', 'дек.'];

function now(): Date {
  return new Date();
}

function ruDateLabel(d: Date): string {
  return `${d.getDate()} ${MONTHS_RU[d.getMonth() + 1]} ${d.getFullYear()}`;
}

function dateOnly(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), d.getDate());
}

function catalogMap() {
  return new Map(CATALOG.map((t) => [t.id, t]));
}

function setMeters(t: (typeof CATALOG)[number]): number {
  const reps = t.presetReps <= 0 ? 1 : t.presetReps;
  const interval = t.presetIntervalMeters <= 0 ? 0 : t.presetIntervalMeters;
  return reps * interval;
}

function buildSets(comboIds: string[]) {
  const cat = catalogMap();
  const sets: Record<string, unknown>[] = [];
  let total = 0;
  const strokeKeys = new Set<string>();
  for (const id of comboIds) {
    const t = cat.get(id);
    if (!t) continue;
    const meters = setMeters(t);
    total += meters;
    strokeKeys.add(t.strokeKey);
    const reps = t.presetReps <= 0 ? 1 : t.presetReps;
    const interval = t.presetIntervalMeters <= 0 ? 0 : t.presetIntervalMeters;
    sets.push({
      title: reps > 1 ? `${reps} × ${interval} м` : `${interval} м`,
      subtitle: STROKE_RU[t.strokeKey] ?? 'Вольный стиль',
      meters,
      strokeKey: t.strokeKey,
      intensityIndex: t.defaultIntensityTier,
      intensityLabel: ['Восстановление', 'Низкая', 'Средняя', 'Высокая'][t.defaultIntensityTier] ?? 'Средняя',
    });
  }
  return { sets, totalMeters: total, strokeKeys };
}

function strokeLabel(keys: Set<string>): string {
  if (keys.size >= 2) return 'КОМПЛЕКС';
  return STROKE_LABEL[[...keys][0] ?? 'free'] ?? 'КРОЛЬ';
}

function pacePer100(meters: number, sec: number): string {
  if (meters <= 0 || sec <= 0) return '—';
  const per100 = (sec / meters) * 100;
  return `${Math.floor(per100 / 60)}:${Math.round(per100 % 60).toString().padStart(2, '0')}`;
}

function estimateKcal(meters: number, sec: number, mood: string, fatigue: number): number {
  const km = meters / 1000;
  const hours = sec > 0 ? sec / 3600 : km / 2.2;
  let kcal = km * 198 * 1.02;
  if (hours > 0 && km / hours > 2.6) kcal *= 1.06;
  kcal *= 1 + (fatigue - 5) * 0.014;
  const moodN = Number.parseInt(mood, 10);
  if (!Number.isNaN(moodN)) kcal *= 1 + (moodN / 4 - 0.5) * 0.04;
  return Math.min(6000, Math.max(18, Math.round(kcal)));
}

function trainingDates(): Date[] {
  const today = dateOnly(new Date());
  const out: Date[] = [];
  for (let offset = -14; offset <= 3; offset++) {
    const d = new Date(today);
    d.setDate(d.getDate() + offset);
    const dow = d.getDay();
    if (dow === 0 || dow === 2 || dow === 4 || dow === 6) out.push(d);
  }
  return out;
}

function createGoogleAuth(): GoogleAuth {
  const cfg = JSON.parse(readFileSync(join(homedir(), '.config/configstore/firebase-tools.json'), 'utf8')) as {
    tokens?: { refresh_token?: string };
  };
  const refreshToken = cfg.tokens?.refresh_token;
  if (!refreshToken) throw new Error('npx firebase-tools login');
  return new GoogleAuth({
    credentials: {
      type: 'authorized_user',
      client_id: CLIENT_ID,
      client_secret: CLIENT_SECRET,
      refresh_token: refreshToken,
    },
    scopes: ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/identitytoolkit'],
  });
}

async function identityPost(auth: GoogleAuth, path: string, body: Record<string, unknown>) {
  const token = await auth.getAccessToken();
  const res = await fetch(`https://identitytoolkit.googleapis.com/v1/projects/${PROJECT_ID}${path}`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`Identity ${path}: ${res.status} ${text}`);
  return text ? JSON.parse(text) : {};
}

async function wipeAuth(auth: GoogleAuth) {
  const users: { localId: string; email?: string }[] = [];
  let pageToken: string | undefined;
  do {
    const body: Record<string, unknown> = { returnUserInfo: true, maxResults: 1000 };
    if (pageToken) body.pageToken = pageToken;
    const page = (await identityPost(auth, '/accounts:query', body)) as {
      userInfo?: { localId: string; email?: string }[];
      nextPageToken?: string;
    };
    users.push(...(page.userInfo ?? []));
    pageToken = page.nextPageToken;
  } while (pageToken);
  for (const u of users) {
    await identityPost(auth, '/accounts:delete', { localId: u.localId });
    console.log(`Auth удалён: ${u.email ?? u.localId}`);
  }
}

async function ensureUser(auth: GoogleAuth, email: string): Promise<string> {
  const page = (await identityPost(auth, '/accounts:query', { returnUserInfo: true, maxResults: 1000 })) as {
    userInfo?: { localId: string; email?: string }[];
  };
  const found = page.userInfo?.find((u) => u.email?.toLowerCase() === email.toLowerCase());
  if (found) {
    await identityPost(auth, '/accounts:update', {
      localId: found.localId,
      email,
      emailVerified: true,
      password: PASSWORD,
      returnSecureToken: false,
    });
    return found.localId;
  }
  const created = (await identityPost(auth, '/accounts', {
    email,
    password: PASSWORD,
    emailVerified: true,
    disabled: false,
  })) as { localId: string };
  return created.localId;
}

async function main() {
  console.log('=== Firestore wipe (CLI) ===');
  execSync(`npx -y firebase-tools@latest firestore:delete --all-collections --project ${PROJECT_ID} --force`, {
    stdio: 'inherit',
  });
  try {
    execSync(
      `npx -y firebase-tools@latest firestore:delete coach_registration_requests --project ${PROJECT_ID} --recursive --force`,
      { stdio: 'pipe' },
    );
  } catch {
    // empty
  }

  const googleAuth = createGoogleAuth();
  console.log('=== Auth wipe ===');
  await wipeAuth(googleAuth);

  const db = new FirestoreRest(googleAuth);
  const ts = now();

  console.log('=== Справочники ===');
  for (const t of CATALOG) {
    await db.setDoc(`catalog_exercises/${t.id}`, {
      title: t.title,
      hint: t.hint,
      presetReps: t.presetReps,
      presetIntervalMeters: t.presetIntervalMeters,
      defaultIntensityTier: t.defaultIntensityTier,
      templateType: t.templateType,
      strokeKey: t.strokeKey,
      sortOrder: t.sortOrder,
      updatedAt: ts,
    });
  }
  for (const [rankId, entries] of Object.entries(RB_2026_RANK_NORMS)) {
    await db.setDoc(`rank_norms/${rankId}`, { rankId, source: RB_2026_SOURCE, entries: entries as never, updatedAt: ts });
  }

  const adminUid = await ensureUser(googleAuth, ACCOUNTS.admin.email);
  const coachUid = await ensureUser(googleAuth, ACCOUNTS.coach.email);

  const userBase = {
    avatarUrl: '',
    avatarPreset: '',
    createdAt: ts,
    updatedAt: ts,
  };

  await db.setDoc(`users/${adminUid}`, {
    ...userBase,
    email: ACCOUNTS.admin.email,
    displayName: ACCOUNTS.admin.displayName,
    sportRank: '',
    role: 'admin',
    city: 'Минск',
  });

  await db.setDoc(`users/${coachUid}`, {
    ...userBase,
    email: ACCOUNTS.coach.email,
    displayName: ACCOUNTS.coach.displayName,
    sportRank: '',
    role: 'coach',
    city: 'Минск',
    coachVerificationStatus: 'approved',
  });

  await db.setDoc(`coach_registration_requests/${coachUid}`, {
    uid: coachUid,
    email: ACCOUNTS.coach.email,
    displayName: ACCOUNTS.coach.displayName,
    status: 'approved',
    certificateUrls: ['https://example.invalid/coach-cert.pdf'],
    reviewedAt: ts,
    updatedAt: ts,
  });

  const days = trainingDates();
  for (let si = 0; si < ACCOUNTS.swimmers.length; si++) {
    const s = ACCOUNTS.swimmers[si];
    const uid = await ensureUser(googleAuth, s.email);
    const goalCs = 6200 + si * 80;

    await db.setDoc(`users/${uid}`, {
      ...userBase,
      email: s.email,
      displayName: s.name,
      sportRank: s.rank,
      role: 'swimmer',
      city: 'Минск',
      coachId: coachUid,
      trainingGroup: s.group,
    });

    await db.setDoc(`users/${coachUid}/athleteDossiers/${uid}`, {
      fullName: s.name,
      birthYear: 2008 + (si % 5),
      phone: `+37529${(1000000 + si * 11111).toString().slice(0, 7)}`,
      city: 'Минск',
      notes: 'Тестовый пловец',
      medicalNotes: '',
      parentContact: '',
      updatedAt: ts,
    });

    await db.setDoc(`users/${uid}/performance_goal/free_100_25`, {
      strokeKey: 'free',
      distanceMeters: 100,
      poolLengthMeters: 25,
      targetTimeCentiseconds: goalCs,
      updatedAt: ts,
    });
    await db.setDoc(`users/${uid}/performance_goal/back_200_25`, {
      strokeKey: 'back',
      distanceMeters: 200,
      poolLengthMeters: 25,
      targetTimeCentiseconds: goalCs + 2800,
      updatedAt: ts,
    });

    for (const [ci, row] of [
      [120, goalCs + 450 + si * 10],
      [60, goalCs + 220],
      [20, goalCs - 80 - si * 5],
    ].entries()) {
      const ev = new Date();
      ev.setDate(ev.getDate() - row[0]);
      await db.setDoc(`users/${uid}/competition_swims/cs100_${ci}`, {
        eventDate: ev,
        distanceMeters: 100,
        strokeKey: 'free',
        timeCentiseconds: row[1],
        poolLengthMeters: 25,
        city: 'Минск',
        competitionName: `Кубок города #${ci + 1}`,
        createdAt: ts,
      });
    }

    if (si < 4) {
      for (const [fi, row] of [
        [90, 3200 + si * 40],
        [30, 3050 + si * 25],
      ].entries()) {
        const ev = new Date();
        ev.setDate(ev.getDate() - row[0]);
        await db.setDoc(`users/${uid}/competition_swims/cs50_${fi}`, {
          eventDate: ev,
          distanceMeters: 50,
          strokeKey: 'free',
          timeCentiseconds: row[1],
          poolLengthMeters: 25,
          city: 'Минск',
          competitionName: `Спринт ${fi + 1}`,
          createdAt: ts,
        });
      }
    }

    const cat = catalogMap();
    let wi = 0;
    for (const day of days) {
      const combo = COMBOS[wi % COMBOS.length];
      wi++;
      const built = buildSets(combo);
      const scheduledAt = new Date(day.getFullYear(), day.getMonth(), day.getDate(), 17, 30);
      const isPast = scheduledAt.getTime() < Date.now();
      const durationSeconds = Math.max(1800, Math.round(built.totalMeters * 1.35));
      const mood = String(2 + (wi % 3));
      const fatigue = 4 + (wi % 5);
      const recordMeta: Record<string, unknown> = { sets: built.sets };
      if (isPast) {
        recordMeta.mood = mood;
        recordMeta.fatigue = fatigue;
        recordMeta.physicalState = wi % 3 === 0 ? 'energy' : 'normal';
        recordMeta.wellbeingSaved = true;
        recordMeta.wellbeingSavedAt = scheduledAt;
      }
      const title = combo.map((id) => cat.get(id)?.title).filter(Boolean).join(' · ');
      await db.setDoc(`users/${uid}/workouts/w_${wi}`, {
        title: title.length > 80 ? title.slice(0, 80) : title,
        scheduledAt,
        distanceMeters: built.totalMeters,
        durationSeconds,
        poolName: '25 м',
        coachId: coachUid,
        recordMeta,
      });
    }
  }

  console.log('\n=== Готово ===');
  console.log(`Пароль: ${PASSWORD}`);
  console.log(`admin=${ACCOUNTS.admin.email} coach=${ACCOUNTS.coach.email}`);
  console.log(`Пловцы: ${ACCOUNTS.swimmers.map((x) => x.email).join(', ')}`);
  console.log(`Тренировок на пловца: ${days.length}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
