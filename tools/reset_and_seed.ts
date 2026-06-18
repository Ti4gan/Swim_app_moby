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

const CITIES = [
  'Минск', 'Брест', 'Витебск', 'Гомель', 'Гродно', 'Могилёв',
  'Борисов', 'Лида', 'Пинск', 'Молодечно', 'Барановичи', 'Новополоцк',
  'Бобруйск', 'Слуцк', 'Жлобин', 'Орша', 'Солигорск', 'Мозырь',
  'Речица', 'Кобрин', 'Светлогорск', 'Полоцк', 'Калинковичи',
];

const ACCOUNTS = {
  admin: { email: 'admin@mail.ru', displayName: 'Админ Системы' },
  coach: { email: 'coach@mail.ru', displayName: 'Игорь Тренеров' },
  swimmers: [
    { email: 'swimmer1@mail.ru', name: 'Анна Смирнова', rank: 'first_youth', group: 'sprint' },
    { email: 'swimmer2@mail.ru', name: 'Максим Орлов', rank: 'second_youth', group: 'distance' },
    { email: 'swimmer3@mail.ru', name: 'Дарья Попова', rank: 'third_youth', group: 'mixed' },
    { email: 'swimmer4@mail.ru', name: 'Сергей Ковалёв', rank: 'first_adult', group: 'sprint' },
    { email: 'swimmer5@mail.ru', name: 'Ольга Новикова', rank: 'second_adult', group: 'distance' },
    { email: 'swimmer6@mail.ru', name: 'Кирилл Зайцев', rank: 'third_adult', group: 'mixed' },
    { email: 'swimmer7@mail.ru', name: 'Екатерина Литвин', rank: 'no_rank', group: 'sprint' },
  ],
};

const WORKOUT_DAYS = [1, 5, 9, 13, 17, 21, 25];
const COMP_DAYS = [3, 7, 10, 15, 20, 24, 28];

const CATALOG = [
  { id: 'warm400', sortOrder: 0, title: 'Разминка вольным стилем', hint: 'Постепенное ускорение каждые 100 м', presetReps: 1, presetIntervalMeters: 400, defaultIntensityTier: 0, templateType: 'warmup', strokeKey: 'free' },
  { id: 'kick8x50', sortOrder: 1, title: 'Ноги с доской', hint: 'Отдых 15 с', presetReps: 8, presetIntervalMeters: 50, defaultIntensityTier: 1, templateType: 'technique', strokeKey: 'free' },
  { id: 'pull6x100', sortOrder: 2, title: 'Руки с лопатками', hint: 'Отдых 20 с', presetReps: 6, presetIntervalMeters: 100, defaultIntensityTier: 1, templateType: 'technique', strokeKey: 'free' },
  { id: 'aerobic10x200', sortOrder: 3, title: 'Аэробная серия кроль', hint: 'RPE 6–7', presetReps: 10, presetIntervalMeters: 200, defaultIntensityTier: 1, templateType: 'aerobic', strokeKey: 'free' },
  { id: 'threshold8x150', sortOrder: 4, title: 'Порог 8×150 м', hint: 'Отдых 20 с', presetReps: 8, presetIntervalMeters: 150, defaultIntensityTier: 2, templateType: 'threshold', strokeKey: 'free' },
  { id: 'sprint12x25', sortOrder: 5, title: 'Спринт 12×25 м', hint: 'Отдых 30–45 с', presetReps: 12, presetIntervalMeters: 25, defaultIntensityTier: 3, templateType: 'sprint', strokeKey: 'free' },
  { id: 'im400', sortOrder: 6, title: 'Комплекс IM 4×100 м', hint: 'По стилям', presetReps: 4, presetIntervalMeters: 100, defaultIntensityTier: 2, templateType: 'im', strokeKey: 'im' },
  { id: 'cool300', sortOrder: 7, title: 'Заминка вольным', hint: 'Расслабленно', presetReps: 1, presetIntervalMeters: 300, defaultIntensityTier: 0, templateType: 'cooldown', strokeKey: 'free' },
];

const COMBOS = [
  ['warm400', 'aerobic10x200', 'cool300'],
  ['warm400', 'kick8x50', 'pull6x100', 'cool300'],
  ['warm400', 'threshold8x150', 'cool300'],
  ['warm400', 'sprint12x25', 'kick8x50', 'cool300'],
  ['warm400', 'im400', 'aerobic10x200', 'cool300'],
  ['warm400', 'pull6x100', 'threshold8x150', 'cool300'],
  ['warm400', 'kick8x50', 'sprint12x25', 'im400', 'cool300'],
];

const COMP_NAMES = [
  'Чемпионат города Минска',
  'Кубок Беларуси',
  'Открытое первенство области',
  'Республиканские соревнования',
  'Международный турнир «Днепр»',
  'Чемпионат страны',
  'Кубок Федерации',
];

const RANK_NORMS: Record<string, Record<string, number>> = {
  first_youth: {
    free_50: 3100, free_100: 6600, free_200: 14400,
    back_50: 3500, back_100: 7500,
    breast_50: 3600, breast_100: 8300,
    fly_50: 3400, fly_100: 7300,
  },
  second_youth: {
    free_50: 3300, free_100: 7000, free_200: 15300,
    back_50: 3700, back_100: 8000,
    breast_50: 3900, breast_100: 8800,
    fly_50: 3600, fly_100: 7800,
  },
  third_youth: {
    free_50: 3500, free_100: 7400, free_200: 16200,
    back_50: 3900, back_100: 8500,
    breast_50: 4200, breast_100: 9400,
    fly_50: 3800, fly_100: 8300,
  },
  first_adult: {
    free_50: 2550, free_100: 5500, free_200: 12000,
    back_50: 2850, back_100: 6200, back_200: 13200,
    breast_50: 3100, breast_100: 6900, breast_200: 14800,
    fly_50: 2750, fly_100: 6000, fly_200: 12900,
    im_100: 6300, im_200: 13500,
  },
  second_adult: {
    free_50: 2700, free_100: 5800, free_200: 12700,
    back_50: 3000, back_100: 6600, back_200: 14200,
    breast_50: 3300, breast_100: 7300, breast_200: 15800,
    fly_50: 2900, fly_100: 6400, fly_200: 13800,
    im_100: 6700, im_200: 14300,
  },
  third_adult: {
    free_50: 2900, free_100: 6200, free_200: 13500,
    back_50: 3200, back_100: 7000, back_200: 15200,
    breast_50: 3500, breast_100: 7800, breast_200: 16800,
    fly_50: 3100, fly_100: 6800, fly_200: 14800,
    im_100: 7100, im_200: 15200,
  },
};

const NO_RANK_BASE: Record<string, number> = {
  free_50: 3800, free_100: 8000, free_200: 17000,
  back_50: 4200, back_100: 9000,
  breast_50: 4500, breast_100: 10000,
};

const STROKE_RU: Record<string, string> = {
  free: 'Вольный стиль', breast: 'Брасс', back: 'На спине', fly: 'Баттерфляй', im: 'Комплекс',
};

function pickCity(): string {
  return CITIES[Math.floor(Math.random() * CITIES.length)];
}

function compTimeCs(rank: string, strokeKey: string, distanceMeters: number): number {
  if (rank === 'no_rank') {
    const norm = NO_RANK_BASE[`${strokeKey}_${distanceMeters}`] ?? 8000;
    return norm - Math.floor(Math.random() * 300) - 50;
  }
  const norms = RANK_NORMS[rank];
  const norm = norms?.[`${strokeKey}_${distanceMeters}`];
  if (!norm) return 8000;
  return norm - Math.floor(Math.random() * 400) - 100;
}

function pickDisciplines(rank: string, count: number): string[] {
  const norms = RANK_NORMS[rank];
  if (!norms) {
    return Array.from({ length: count }, () => 'free_100');
  }
  const keys = Object.keys(norms);
  for (let i = keys.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [keys[i], keys[j]] = [keys[j], keys[i]];
  }
  return keys.slice(0, count);
}

function juneDate(day: number, hour = 10): Date {
  return new Date(2026, 5, day, hour, Math.floor(Math.random() * 60));
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
  for (const id of comboIds) {
    const t = cat.get(id);
    if (!t) continue;
    const meters = setMeters(t);
    total += meters;
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
  return { sets, totalMeters: total };
}

function goalTimeCs(rank: string, strokeKey: string, distanceMeters: number): number {
  if (rank === 'no_rank') return 8000;
  const norm = RANK_NORMS[rank]?.[`${strokeKey}_${distanceMeters}`];
  return norm ?? 8000;
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
    console.log(`  Auth удалён: ${u.email ?? u.localId}`);
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
  console.log('\n=== 1/6 Wipe Firestore ===');
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

  const auth = createGoogleAuth();
  console.log('\n=== 2/6 Wipe Auth ===');
  await wipeAuth(auth);

  const db = new FirestoreRest(auth);
  const ts = new Date();

  console.log('\n=== 3/6 Справочники ===');
  for (const t of CATALOG) {
    await db.setDoc(`catalog_exercises/${t.id}`, {
      title: t.title, hint: t.hint,
      presetReps: t.presetReps, presetIntervalMeters: t.presetIntervalMeters,
      defaultIntensityTier: t.defaultIntensityTier, templateType: t.templateType,
      strokeKey: t.strokeKey, sortOrder: t.sortOrder,
      updatedAt: ts,
    });
  }
  console.log(`  catalog_exercises: ${CATALOG.length}`);

  for (const [rankId, entries] of Object.entries(RB_2026_RANK_NORMS)) {
    await db.setDoc(`rank_norms/${rankId}`, { rankId, source: RB_2026_SOURCE, entries: entries as never, updatedAt: ts });
  }
  console.log(`  rank_norms: ${Object.keys(RB_2026_RANK_NORMS).length}`);

  const adminUid = await ensureUser(auth, ACCOUNTS.admin.email);
  const coachUid = await ensureUser(auth, ACCOUNTS.coach.email);

  const userBase = { avatarUrl: '', avatarPreset: '', createdAt: ts, updatedAt: ts };

  console.log('\n=== 4/6 Администратор и тренер ===');
  await db.setDoc(`users/${adminUid}`, {
    ...userBase, email: ACCOUNTS.admin.email,
    displayName: ACCOUNTS.admin.displayName, sportRank: '',
    role: 'admin', city: 'Минск',
  });
  console.log(`  admin: ${ACCOUNTS.admin.email} / ${PASSWORD}`);

  const coachCity = pickCity();
  await db.setDoc(`users/${coachUid}`, {
    ...userBase, email: ACCOUNTS.coach.email,
    displayName: ACCOUNTS.coach.displayName, sportRank: '',
    role: 'coach', city: coachCity,
    profileComplete: true, coachVerificationStatus: 'approved',
  });
  await db.setDoc(`coach_registration_requests/${coachUid}`, {
    uid: coachUid, email: ACCOUNTS.coach.email,
    displayName: ACCOUNTS.coach.displayName, status: 'approved',
    certificateUrls: ['https://example.invalid/coach-cert.pdf'],
    reviewedAt: ts, updatedAt: ts,
  });
  const inviteCode = 'COACH1';
  await db.setDoc(`coach_invites/${inviteCode}`, { coachId: coachUid, createdAt: ts });
  console.log(`  coach: ${ACCOUNTS.coach.email} / ${PASSWORD}, city: ${coachCity}, invite: ${inviteCode}`);

  console.log('\n=== 5/6 Пловцы ===');
  const swimmerUids: string[] = [];
  for (const s of ACCOUNTS.swimmers) {
    const uid = await ensureUser(auth, s.email);
    swimmerUids.push(uid);
  }

  console.log('\n=== 6/6 Данные пловцов ===');
  for (let si = 0; si < ACCOUNTS.swimmers.length; si++) {
    const s = ACCOUNTS.swimmers[si];
    const uid = swimmerUids[si];
    const city = pickCity();

    await db.setDoc(`users/${uid}`, {
      ...userBase, email: s.email, displayName: s.name, sportRank: s.rank,
      role: 'swimmer', city, coachId: coachUid, trainingGroup: s.group,
      coachInviteLabel: 'Приглашён тренером',
    });

    await db.setDoc(`users/${coachUid}/athleteDossiers/${uid}`, {
      fullName: s.name, birthYear: 2006 + (si % 6),
      phone: `+37529${(1000000 + si * 11111).toString().slice(0, 7)}`,
      city, notes: `Перспективный спортсмен, группа ${s.group}`,
      medicalNotes: si % 3 === 0 ? 'Аллергия на хлор (использовать очки)' : '',
      parentContact: si % 2 === 0 ? `+37529${(2000000 + si * 22222).toString().slice(0, 7)}` : '',
      updatedAt: ts,
    });

    // Performance goals
    if (s.rank !== 'no_rank') {
      const isAdult = ['first_adult', 'second_adult', 'third_adult'].includes(s.rank);
      const goals = [
        { strokeKey: 'free', distanceMeters: 100, poolLengthMeters: 25 },
        { strokeKey: 'free', distanceMeters: 200, poolLengthMeters: 25 },
        isAdult
          ? { strokeKey: 'im', distanceMeters: 200, poolLengthMeters: 25 }
          : { strokeKey: 'back', distanceMeters: 100, poolLengthMeters: 25 },
      ];
      for (const g of goals) {
        const docId = `${g.strokeKey}_${g.distanceMeters}_${g.poolLengthMeters}`;
        const target = goalTimeCs(s.rank, g.strokeKey, g.distanceMeters);
        await db.setDoc(`users/${uid}/performance_goal/${docId}`, {
          strokeKey: g.strokeKey, distanceMeters: g.distanceMeters,
          poolLengthMeters: g.poolLengthMeters, targetTimeCentiseconds: target,
          coachId: coachUid, updatedAt: ts,
        });
      }
    }

    // Competition swims (4-7 per swimmer)
    const compCount = Math.min(4 + (si % 4), COMP_DAYS.length);
    const discs = pickDisciplines(s.rank, compCount);
    for (let ci = 0; ci < compCount && ci < discs.length; ci++) {
      const parts = discs[ci].split('_');
      const strokeKey = parts[0];
      const distanceMeters = parseInt(parts[1], 10);
      const eventDate = juneDate(COMP_DAYS[ci]);
      const timeCs = compTimeCs(s.rank, strokeKey, distanceMeters);
      await db.setDoc(`users/${uid}/competition_swims/cs_${ci}`, {
        eventDate, distanceMeters, strokeKey, timeCentiseconds: timeCs,
        poolLengthMeters: 25, city: pickCity(),
        competitionName: COMP_NAMES[ci % COMP_NAMES.length],
        createdAt: ts,
      });
    }

    // Workouts from coach (5-7 per swimmer)
    const wCount = Math.min(5 + (si % 3), WORKOUT_DAYS.length);
    const cat = catalogMap();
    for (let wi = 0; wi < wCount; wi++) {
      const combo = COMBOS[wi % COMBOS.length];
      const built = buildSets(combo);
      const scheduledAt = juneDate(WORKOUT_DAYS[wi], 17);
      const isPast = scheduledAt < new Date();
      const durationSec = Math.max(1800, Math.round(built.totalMeters * 1.35));

      const recordMeta: Record<string, unknown> = { sets: built.sets, enteredByCoach: true };
      if (isPast) {
        recordMeta.mood = String(3 + (wi % 5));
        recordMeta.fatigue = Math.min(10, 4 + (wi % 6));
        recordMeta.physicalState = wi % 3 === 0 ? 'energy' : wi % 3 === 1 ? 'normal' : 'tired';
        recordMeta.wellbeingSaved = true;
        recordMeta.wellbeingSavedAt = scheduledAt;
      }

      const rawTitle = combo.map((id) => cat.get(id)?.title).filter(Boolean).join(' · ');
      const title = rawTitle.length > 80 ? rawTitle.slice(0, 80) : rawTitle;
      await db.setDoc(`users/${uid}/workouts/w_${wi}`, {
        title, scheduledAt, distanceMeters: built.totalMeters,
        durationSeconds: durationSec, poolName: '25 м',
        coachId: coachUid, recordMeta,
      });
    }

    console.log(`  ${s.name} — rank ${s.rank}, city: ${city}`);
  }

  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('✅ SEED COMPLETE');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log(`📧 admin: ${ACCOUNTS.admin.email} / ${PASSWORD}`);
  console.log(`📧 coach: ${ACCOUNTS.coach.email} / ${PASSWORD}`);
  console.log(`🔑 invite: ${inviteCode}`);
  console.log(`👥 swimmers: ${ACCOUNTS.swimmers.map((s) => s.email).join(', ')}`);
  console.log(`📅 June 2026 data (${WORKOUT_DAYS.length} workouts, ${COMP_DAYS.length} comp dates)`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
