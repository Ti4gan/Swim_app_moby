import { initializeApp } from 'firebase/app';
import {
  getAuth,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from 'firebase/auth';
import { getFunctions, httpsCallable } from 'firebase/functions';
import {
  collection,
  deleteDoc,
  deleteField,
  doc,
  getDoc,
  getDocs,
  getFirestore,
  orderBy,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  writeBatch,
} from 'firebase/firestore';
import { getStorage, ref as storageRef, getDownloadURL } from 'firebase/storage';
import { RB_2026_RANK_NORMS, RB_2026_SOURCE, type NormEntry } from './rank_norms_rb_2026';
import { normsTableHtml, rankOptionsHtml, readNormsFromTable } from './rank_norms_ui';
import { roleLabel } from './reports/constants';
import { catalogVolumeMeters } from './reports/derived';
import { renderReports } from './reports/ui';

const COL = {
  users: 'users',
  coachRegistrationRequests: 'coach_registration_requests',
  catalogExercises: 'catalog_exercises',
  rankNorms: 'rank_norms',
};

const RANK_IDS = [
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

const RANK_LABELS: Record<string, string> = {
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

const TEMPLATE_TYPE_OPTIONS: [string, string][] = [
  ['warmup', 'Разминка'],
  ['technique', 'Техника'],
  ['aerobic', 'Аэробика'],
  ['threshold', 'Порог'],
  ['sprint', 'Спринт'],
  ['im', 'Комплекс'],
  ['cooldown', 'Заминка'],
];

const STROKE_OPTIONS: [string, string][] = [
  ['free', 'Вольный'],
  ['breast', 'Брасс'],
  ['fly', 'Баттерфляй'],
  ['back', 'На спине'],
  ['im', 'Комплекс'],
];

type UserFormValues = {
  displayName: string;
  email: string;
  role: string;
  coachId: string;
  sportRank: string;
  city: string;
};

type CatalogFormValues = {
  title: string;
  hint: string;
  presetReps: number;
  presetIntervalMeters: number;
  defaultIntensityTier: number;
  sortOrder: number;
  templateType: string;
  strokeKey: string;
};

function optionsHtml(
  items: [string, string][],
  selected: string,
  emptyOption?: { value: string; label: string },
): string {
  const opts: string[] = [];
  if (emptyOption) {
    const sel = selected === emptyOption.value ? ' selected' : '';
    opts.push(`<option value="${escapeHtml(emptyOption.value)}"${sel}>${escapeHtml(emptyOption.label)}</option>`);
  }
  for (const [value, label] of items) {
    const sel = value === selected ? ' selected' : '';
    opts.push(`<option value="${escapeHtml(value)}"${sel}>${escapeHtml(label)}</option>`);
  }
  return opts.join('');
}

function userFormFieldsHtml(
  prefix: string,
  coaches: { id: string; name: string }[],
  values: UserFormValues,
): string {
  return `
    <div class="grid2">
      <label>ФИО (обяз.)<br/><input type="text" id="${prefix}-name" value="${escapeHtml(values.displayName)}" /></label>
      <label>Почта (обяз.)<br/><input type="email" id="${prefix}-email" value="${escapeHtml(values.email)}" /></label>
      <label>Роль (обяз.)<br/>
        <select id="${prefix}-role">
          ${optionsHtml(
            [
              ['swimmer', 'Пловец'],
              ['coach', 'Тренер'],
              ['admin', 'Администратор'],
            ],
            values.role,
          )}
        </select>
      </label>
      <label>Тренер<br/>
        <select id="${prefix}-coach">${coachOptionsHtml(coaches, values.coachId)}</select>
      </label>
      <label>Разряд<br/>
        <select id="${prefix}-rank">${rankOptionsHtml(RANK_IDS, RANK_LABELS, values.sportRank)}</select>
      </label>
      <label>Город<br/><input type="text" id="${prefix}-city" value="${escapeHtml(values.city)}" /></label>
    </div>
  `;
}

function readUserForm(root: ParentNode, prefix: string): UserFormValues {
  return {
    displayName: (root.querySelector(`#${prefix}-name`) as HTMLInputElement).value.trim(),
    email: (root.querySelector(`#${prefix}-email`) as HTMLInputElement).value.trim(),
    role: (root.querySelector(`#${prefix}-role`) as HTMLSelectElement).value,
    coachId: (root.querySelector(`#${prefix}-coach`) as HTMLSelectElement).value.trim(),
    sportRank: (root.querySelector(`#${prefix}-rank`) as HTMLSelectElement).value.trim(),
    city: (root.querySelector(`#${prefix}-city`) as HTMLInputElement).value.trim(),
  };
}

function userPatchFromForm(values: UserFormValues): Record<string, unknown> {
  const patch: Record<string, unknown> = {
    displayName: values.displayName,
    email: values.email,
    role: values.role,
    city: values.city,
    updatedAt: serverTimestamp(),
  };
  if (values.sportRank) patch.sportRank = values.sportRank;
  if (values.coachId) {
    patch.coachId = values.coachId;
  } else {
    patch.coachId = deleteField();
  }
  return patch;
}

function catalogFormFieldsHtml(
  prefix: string,
  values: CatalogFormValues,
  exerciseId = '',
): string {
  const idField = exerciseId
    ? `<label>Код упражнения<br/><input type="text" value="${escapeHtml(exerciseId)}" disabled /></label>`
    : `<label>Код упражнения (латиница, обяз.)<br/><input type="text" id="${prefix}-id" /></label>`;
  return `
    <div class="grid2">
      ${idField}
      <label>sortOrder<br/><input type="number" id="${prefix}-so" value="${values.sortOrder}" /></label>
      <label>Название<br/><input type="text" id="${prefix}-title" value="${escapeHtml(values.title)}" /></label>
      <label>Подсказка<br/><input type="text" id="${prefix}-hint" value="${escapeHtml(values.hint)}" /></label>
      <label>Повторы<br/><input type="number" id="${prefix}-pr" value="${values.presetReps}" /></label>
      <label>Интервал метры<br/><input type="number" id="${prefix}-im" value="${values.presetIntervalMeters}" /></label>
      <label>Интенсивность 0–3<br/><input type="number" id="${prefix}-it" min="0" max="3" value="${values.defaultIntensityTier}" /></label>
      <label>Тип блока<br/>
        <select id="${prefix}-tt">${optionsHtml(TEMPLATE_TYPE_OPTIONS, values.templateType)}</select>
      </label>
      <label>Стиль<br/>
        <select id="${prefix}-sk">${optionsHtml(STROKE_OPTIONS, values.strokeKey)}</select>
      </label>
    </div>
  `;
}

function readCatalogForm(root: ParentNode, prefix: string): CatalogFormValues & { id: string } {
  const idEl = root.querySelector(`#${prefix}-id`) as HTMLInputElement | null;
  return {
    id: idEl?.value.trim() ?? '',
    title: (root.querySelector(`#${prefix}-title`) as HTMLInputElement).value.trim(),
    hint: (root.querySelector(`#${prefix}-hint`) as HTMLInputElement).value.trim(),
    presetReps: Number((root.querySelector(`#${prefix}-pr`) as HTMLInputElement).value) || 1,
    presetIntervalMeters: Number((root.querySelector(`#${prefix}-im`) as HTMLInputElement).value) || 0,
    defaultIntensityTier: Number((root.querySelector(`#${prefix}-it`) as HTMLInputElement).value) || 0,
    sortOrder: Number((root.querySelector(`#${prefix}-so`) as HTMLInputElement).value) || 0,
    templateType: (root.querySelector(`#${prefix}-tt`) as HTMLSelectElement).value,
    strokeKey: (root.querySelector(`#${prefix}-sk`) as HTMLSelectElement).value,
  };
}

function catalogFirestorePayload(values: CatalogFormValues): Record<string, unknown> {
  return {
    title: values.title,
    hint: values.hint,
    presetReps: values.presetReps,
    presetIntervalMeters: values.presetIntervalMeters,
    defaultIntensityTier: values.defaultIntensityTier,
    sortOrder: values.sortOrder,
    templateType: values.templateType,
    strokeKey: values.strokeKey,
    updatedAt: serverTimestamp(),
  };
}

function defaultCatalogValues(): CatalogFormValues {
  return {
    title: '',
    hint: '',
    presetReps: 1,
    presetIntervalMeters: 0,
    defaultIntensityTier: 1,
    sortOrder: 100,
    templateType: 'aerobic',
    strokeKey: 'free',
  };
}

function catalogValuesFromDoc(data: Record<string, unknown>): CatalogFormValues {
  return {
    title: String(data.title ?? ''),
    hint: String(data.hint ?? ''),
    presetReps: Number(data.presetReps ?? 1) || 1,
    presetIntervalMeters: Number(data.presetIntervalMeters ?? 0) || 0,
    defaultIntensityTier: Number(data.defaultIntensityTier ?? 1) || 0,
    sortOrder: Number(data.sortOrder ?? 0) || 0,
    templateType: String(data.templateType ?? 'aerobic'),
    strokeKey: String(data.strokeKey ?? 'free'),
  };
}

function escapeHtml(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function coachOptionsHtml(
  coaches: { id: string; name: string }[],
  selectedId: string,
): string {
  const opts = ['<option value="">— не привязан —</option>'];
  for (const c of coaches) {
    const sel = c.id === selectedId ? ' selected' : '';
    opts.push(`<option value="${escapeHtml(c.id)}"${sel}>${escapeHtml(c.name)}</option>`);
  }
  return opts.join('');
}

export function mount(root: HTMLElement): void {
  const apiKey = import.meta.env.VITE_FIREBASE_API_KEY as string | undefined;
  const authDomain = import.meta.env.VITE_FIREBASE_AUTH_DOMAIN as string | undefined;
  const projectId = import.meta.env.VITE_FIREBASE_PROJECT_ID as string | undefined;
  const storageBucket = import.meta.env.VITE_FIREBASE_STORAGE_BUCKET as string | undefined;
  const messagingSenderId = import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID as string | undefined;
  const appId = import.meta.env.VITE_FIREBASE_APP_ID as string | undefined;

  if (!apiKey || !authDomain || !projectId || !storageBucket || !messagingSenderId || !appId) {
    root.innerHTML = `<div class="card"><p class="err">Заполни переменные VITE_FIREBASE_* в файле <code>admin_web/.env</code> (см. <code>.env.example</code> в этой папке). В консоли Firebase создай веб‑приложение и скопируй конфиг.</p></div>`;
    return;
  }

  const app = initializeApp({
    apiKey,
    authDomain,
    projectId,
    storageBucket,
    messagingSenderId,
    appId,
  });
  const auth = getAuth(app);
  const db = getFirestore(app);
  const functions = getFunctions(app);
  const storage = getStorage(app);

  function coachDocumentLabel(ref: string): string {
    if (ref.startsWith('gdrive:')) {
      const rest = ref.slice('gdrive:'.length);
      const pipe = rest.indexOf('|');
      if (pipe > 0) return rest.slice(pipe + 1);
      return 'документ';
    }
    if (ref.includes('/')) return ref.split('/').pop() || 'файл';
    return 'файл';
  }

  async function resolveCoachDocumentLinks(urls: string[]): Promise<string> {
    const direct = urls.filter((u) => u.startsWith('http://') || u.startsWith('https://'));
    const storagePaths = urls.filter((u) => u.startsWith('coach_documents/'));
    const gdrive = urls.filter(
      (u) =>
        !u.startsWith('http://') &&
        !u.startsWith('https://') &&
        !u.startsWith('coach_documents/'),
    );
    const resolved: Record<string, string> = {};
    for (const path of storagePaths) {
      try {
        resolved[path] = await getDownloadURL(storageRef(storage, path));
      } catch {
        // оставим без ссылки
      }
    }
    if (gdrive.length > 0) {
      const fn = httpsCallable<{ refs: string[] }, { urls: Record<string, string> }>(
        functions,
        'getCoachDocumentDownloadUrls',
      );
      const res = await fn({ refs: gdrive });
      Object.assign(resolved, res.data.urls ?? {});
    }
    for (const u of direct) {
      resolved[u] = u;
    }
    return urls
      .map((u) => {
        const href =
          u.startsWith('http://') || u.startsWith('https://') ? u : (resolved[u] ?? '#');
        const label = coachDocumentLabel(u);
        if (href === '#') {
          return `<div><span class="muted">${escapeHtml(label)} (ссылка недоступна)</span></div>`;
        }
        return `<div><a href="${escapeHtml(href)}" target="_blank" rel="noopener">${escapeHtml(label)}</a></div>`;
      })
      .join('');
  }

  let tab: 'requests' | 'users' | 'catalog' | 'norms' | 'reports' = 'requests';
  let statusLine = '';
  let renderNonce = 0;
  let openUserEditorId: string | null = null;
  let openCatalogEditorId: string | null = null;

  function formatErr(e: unknown): string {
    if (e && typeof e === 'object' && 'code' in e && 'message' in e) {
      return `${(e as { code: string }).code}: ${(e as { message: string }).message}`;
    }
    return String(e);
  }

  async function assertAdmin(uid: string): Promise<boolean> {
    const snap = await getDoc(doc(db, COL.users, uid));
    const role = snap.data()?.role;
    return role === 'admin';
  }

  async function render(): Promise<void> {
    const u = auth.currentUser;
    if (!u) {
      root.innerHTML = `
        <h1>Админ Swimflow</h1>
        <div class="card grid2">
          <label>Email<br/><input type="email" id="em" autocomplete="username" /></label>
          <label>Пароль<br/><input type="password" id="pw" autocomplete="current-password" /></label>
        </div>
        <p style="margin-top:12px"><button class="primary" id="go">Войти</button></p>
        <p id="msg" class="err"></p>
      `;
      document.getElementById('go')?.addEventListener('click', async () => {
        const em = (document.getElementById('em') as HTMLInputElement).value.trim();
        const pw = (document.getElementById('pw') as HTMLInputElement).value;
        const msg = document.getElementById('msg')!;
        msg.textContent = '';
        try {
          await signInWithEmailAndPassword(auth, em, pw);
        } catch (e) {
          msg.textContent = String(e);
        }
      });
      return;
    }

    if (!(await assertAdmin(u.uid))) {
      await signOut(auth);
      root.innerHTML = `<div class="card"><p class="err">У этой учётной записи нет роли admin в Firestore.</p></div>`;
      return;
    }

    const nonce = ++renderNonce;

    root.classList.toggle('reports-wide', tab === 'reports');

    root.innerHTML = `
      <div class="row" style="justify-content:space-between">
        <div>
          <h1>Админ Swimflow</h1>
          <p class="sub">${escapeHtml(u.email ?? '')}</p>
        </div>
        <button class="ghost" id="out">Выйти</button>
      </div>
      ${statusLine ? `<p class="ok">${escapeHtml(statusLine)}</p>` : ''}
      <nav class="tabs">
        <button type="button" data-tab="requests" class="${tab === 'requests' ? 'active' : ''}">Заявки тренеров</button>
        <button type="button" data-tab="users" class="${tab === 'users' ? 'active' : ''}">Пользователи</button>
        <button type="button" data-tab="catalog" class="${tab === 'catalog' ? 'active' : ''}">Каталог упражнений</button>
        <button type="button" data-tab="norms" class="${tab === 'norms' ? 'active' : ''}">Нормативы по разрядам</button>
        <button type="button" data-tab="reports" class="${tab === 'reports' ? 'active' : ''}">Отчёты</button>
      </nav>
      <div id="panel"><p class="sub" style="padding:12px 0">Загрузка…</p></div>
    `;

    document.getElementById('out')?.addEventListener('click', () => signOut(auth));
    root.querySelectorAll('.tabs button').forEach((btn) => {
      btn.addEventListener('click', () => {
        const v = (btn as HTMLElement).dataset.tab;
        if (v === 'requests' || v === 'users' || v === 'catalog' || v === 'norms' || v === 'reports') {
          tab = v;
        }
        statusLine = '';
        void render();
      });
    });

    const panel = document.getElementById('panel')!;
    try {
      if (nonce !== renderNonce) return;
      if (tab === 'requests') await renderRequests(panel);
      else if (tab === 'users') await renderUsers(panel);
      else if (tab === 'catalog') await renderCatalog(panel);
      else if (tab === 'norms') await renderNorms(panel);
      else await renderReports(panel, db, { escapeHtml, onStatus: (line) => { statusLine = line; } });
      if (nonce !== renderNonce) return;
    } catch (e) {
      if (nonce !== renderNonce) return;
      const hint =
        formatErr(e).includes('permission-denied') || formatErr(e).includes('Missing or insufficient permissions')
          ? '<p class="sub">Частая причина: в облаке не задеплоены правила Firestore с доступом admin. В корне проекта выполни: <code>firebase deploy --only firestore:rules</code></p>'
          : '';
      panel.innerHTML = `<div class="card"><p class="err">${escapeHtml(formatErr(e))}</p>${hint}</div>`;
    }
  }

  async function renderRequests(panel: HTMLElement): Promise<void> {
    const snap = await getDocs(collection(db, COL.coachRegistrationRequests));
    if (!panel.isConnected) return;
    const sorted = [...snap.docs].sort((a, b) => {
      const ta = a.data().updatedAt as { toMillis?: () => number } | undefined;
      const tb = b.data().updatedAt as { toMillis?: () => number } | undefined;
      const ma = ta?.toMillis?.() ?? 0;
      const mb = tb?.toMillis?.() ?? 0;
      return mb - ma;
    });
    const rows: string[] = [];
    for (const d of sorted) {
      const x = d.data();
      const urls = (x.certificateUrls as string[] | undefined) ?? [];
      const links = urls.length > 0 ? await resolveCoachDocumentLinks(urls) : '';
      rows.push(`
        <tr>
          <td>${escapeHtml(String(x.displayName ?? ''))}<br/><span style="color:var(--muted);font-size:12px">${escapeHtml(String(x.email ?? ''))}</span></td>
          <td>${escapeHtml(String(x.status ?? ''))}</td>
          <td>${links || '<span class="muted">Нет документов</span>'}</td>
          <td>
            ${x.status === 'pending'
              ? `<button class="primary sm-ok" data-request-id="${escapeHtml(d.id)}">Подтвердить</button> <button class="danger sm-no" data-request-id="${escapeHtml(d.id)}">Отклонить</button>`
              : '—'}
          </td>
        </tr>
      `);
    }
    if (!panel.isConnected) return;
    panel.innerHTML = `
      <h2>Заявки на статус тренера</h2>
      <div class="table-scroll">
        <table class="requests-table">
          <thead><tr><th>ФИО / почта</th><th>Статус</th><th>Документы</th><th></th></tr></thead>
          <tbody>${rows.join('') || '<tr><td colspan="4">Нет заявок</td></tr>'}</tbody>
        </table>
      </div>
    `;
    panel.querySelectorAll('.sm-ok').forEach((b) =>
      b.addEventListener('click', async () => {
        const requestId = (b as HTMLElement).dataset.requestId!;
        const batch = writeBatch(db);
        batch.set(
          doc(db, COL.users, requestId),
          { coachVerificationStatus: 'approved', updatedAt: serverTimestamp() },
          { merge: true },
        );
        batch.set(
          doc(db, COL.coachRegistrationRequests, requestId),
          { status: 'approved', updatedAt: serverTimestamp() },
          { merge: true },
        );
        await batch.commit();
        statusLine = 'Заявка подтверждена';
        await render();
      }),
    );
    panel.querySelectorAll('.sm-no').forEach((b) =>
      b.addEventListener('click', async () => {
        const requestId = (b as HTMLElement).dataset.requestId!;
        const batch = writeBatch(db);
        batch.set(
          doc(db, COL.users, requestId),
          { coachVerificationStatus: 'rejected', updatedAt: serverTimestamp() },
          { merge: true },
        );
        batch.set(
          doc(db, COL.coachRegistrationRequests, requestId),
          { status: 'rejected', updatedAt: serverTimestamp() },
          { merge: true },
        );
        await batch.commit();
        statusLine = 'Заявка отклонена';
        await render();
      }),
    );
  }

  async function renderUsers(panel: HTMLElement): Promise<void> {
    const snap = await getDocs(collection(db, COL.users));
    if (!panel.isConnected) return;

    const idToDisplay = new Map<string, string>();
    const coaches: { id: string; name: string }[] = [];
    for (const d of snap.docs) {
      const name = String(d.data().displayName ?? '').trim();
      idToDisplay.set(d.id, name);
      if (d.data().role === 'coach' && name.length > 0) {
        coaches.push({ id: d.id, name });
      }
    }
    coaches.sort((a, b) => a.name.localeCompare(b.name, 'ru'));

    const rows: string[] = [];
    for (const d of snap.docs) {
      const x = d.data();
      const name = String(x.displayName ?? '');
      const fioKey = name.toLowerCase();
      const role = String(x.role ?? '');
      const coachId = String(x.coachId ?? '').trim();
      let coachHtml = '<span class="muted">—</span>';
      const coachName = coachId ? (idToDisplay.get(coachId) ?? '').trim() : '';
      const coachFioKey = coachName.toLowerCase();
      if (role === 'swimmer' && coachName.length > 0) {
        coachHtml = `<span class="coach-fio-line">${escapeHtml(coachName)}</span>`;
      }

      rows.push(`
        <tr class="user-row" data-fio="${escapeHtml(fioKey)}" data-coach-fio="${escapeHtml(coachFioKey)}" data-role="${escapeHtml(role)}">
          <td class="cell-fio">${escapeHtml(name)}</td>
          <td class="cell-email">${escapeHtml(String(x.email ?? ''))}</td>
          <td class="cell-role">${escapeHtml(roleLabel(role))}</td>
          <td class="coach-col cell-coach">${coachHtml}</td>
          <td class="cell-actions">
            <button type="button" class="ghost sm-ed" data-user-ref="${escapeHtml(d.id)}">Правка</button>
            <button type="button" class="danger sm-del" data-user-ref="${escapeHtml(d.id)}" data-name="${escapeHtml(name)}">Удалить</button>
          </td>
        </tr>
      `);
    }
    if (!panel.isConnected) return;
    panel.innerHTML = `
      <h2>Пользователи (${snap.size})</h2>
      <p class="panel-toolbar">
        <button type="button" class="primary" id="toggle-add-user">Добавить пользователя</button>
      </p>
      <div class="card collapsible-panel" id="add-user-card" hidden>
        <h3>Новый пользователь</h3>
        ${userFormFieldsHtml('new-user', coaches, {
          displayName: '',
          email: '',
          role: 'swimmer',
          coachId: '',
          sportRank: '',
          city: '',
        })}
        <p class="form-actions">
          <button type="button" class="primary" id="add-user-btn">Сохранить</button>
          <button type="button" class="ghost" id="cancel-add-user">Отмена</button>
        </p>
        <p class="err" id="add-user-err"></p>
      </div>
      <div class="filters-bar">
        <label class="filter-field">Поиск по ФИО
          <input type="search" id="user-fio-search" placeholder="Имя или полное ФИО…" autocomplete="off" />
        </label>
        <label class="filter-field">Поиск по ФИО тренера
          <input type="search" id="user-coach-search" placeholder="ФИО тренера…" autocomplete="off" />
        </label>
        <label class="filter-field">Роль
          <select id="user-role-filter">
            <option value="all" selected>Все роли</option>
            <option value="swimmer">Пловцы</option>
            <option value="coach">Тренеры</option>
            <option value="admin">Администраторы</option>
          </select>
        </label>
      </div>
      <div class="table-scroll">
        <table class="users-table">
          <thead><tr><th>ФИО</th><th>Почта</th><th>Роль</th><th>ФИО тренера</th><th></th></tr></thead>
          <tbody id="users-tbody">${rows.join('')}</tbody>
        </table>
      </div>
    `;

    const tbody = panel.querySelector('#users-tbody');
    const addUserCard = panel.querySelector('#add-user-card') as HTMLElement;
    const toggleAddUserBtn = panel.querySelector('#toggle-add-user') as HTMLButtonElement;

    const setAddUserVisible = (visible: boolean): void => {
      addUserCard.hidden = !visible;
      toggleAddUserBtn.textContent = visible ? 'Скрыть форму' : 'Добавить пользователя';
    };

    panel.querySelector('#toggle-add-user')?.addEventListener('click', () => {
      setAddUserVisible(addUserCard.hidden);
    });
    panel.querySelector('#cancel-add-user')?.addEventListener('click', () => {
      setAddUserVisible(false);
    });

    panel.querySelector('#add-user-btn')?.addEventListener('click', async () => {
      const err = panel.querySelector('#add-user-err') as HTMLElement;
      err.textContent = '';
      const values = readUserForm(panel, 'new-user');
      if (!values.displayName || !values.email || !values.role) {
        err.textContent = 'ФИО, почта и роль — обязательные поля.';
        return;
      }
      try {
        const newUserRef = doc(collection(db, COL.users));
        const data: Record<string, unknown> = {
          displayName: values.displayName,
          email: values.email,
          role: values.role,
          city: values.city,
          createdAt: serverTimestamp(),
          updatedAt: serverTimestamp(),
        };
        if (values.sportRank) data.sportRank = values.sportRank;
        if (values.coachId) data.coachId = values.coachId;
        await setDoc(newUserRef, data);
        openUserEditorId = null;
        statusLine = 'Пользователь добавлен';
        await render();
      } catch (e) {
        err.textContent = formatErr(e);
      }
    });
    tbody?.querySelectorAll('.sm-del').forEach((b) => {
      b.addEventListener('click', async () => {
        const userRef = (b as HTMLElement).dataset.userRef!;
        const name = (b as HTMLElement).dataset.name!;
        if (!confirm(`Вы уверены, что хотите удалить пользователя ${name}?`)) return;

        try {
          await deleteDoc(doc(db, COL.users, userRef));
          statusLine = 'Пользователь удален';
          await render();
        } catch (e) {
          alert('Ошибка удаления: ' + formatErr(e));
        }
      });
    });
    const searchFio = panel.querySelector('#user-fio-search') as HTMLInputElement | null;
    const searchCoach = panel.querySelector('#user-coach-search') as HTMLInputElement | null;
    const roleFilter = panel.querySelector('#user-role-filter') as HTMLSelectElement | null;

    const setUserEditActive = (activeId: string | null): void => {
      tbody?.querySelectorAll('.sm-ed').forEach((btn) => {
        btn.classList.toggle('active', (btn as HTMLElement).dataset.userRef === activeId);
      });
    };

    const applyFilter = (): void => {
      const qFio = (searchFio?.value ?? '').trim().toLowerCase();
      const qCoach = (searchCoach?.value ?? '').trim().toLowerCase();
      const roleVal = roleFilter?.value ?? 'all';
      tbody?.querySelectorAll('tr.user-row').forEach((tr) => {
        const el = tr as HTMLElement;
        const fio = el.dataset.fio ?? '';
        const coachFio = el.dataset.coachFio ?? '';
        const r = el.dataset.role ?? '';
        let ok = true;
        if (qFio && !fio.includes(qFio)) ok = false;
        if (qCoach && !coachFio.includes(qCoach)) ok = false;
        if (roleVal !== 'all' && r !== roleVal) ok = false;
        el.hidden = !ok;
        const editor = el.nextElementSibling;
        if (editor?.classList.contains('user-editor-row')) {
          (editor as HTMLElement).hidden = !ok;
        }
      });
    };
    searchFio?.addEventListener('input', applyFilter);
    searchCoach?.addEventListener('input', applyFilter);
    roleFilter?.addEventListener('change', applyFilter);

    tbody?.querySelectorAll('.sm-ed').forEach((b) => {
      b.addEventListener('click', () => {
        const userRef = (b as HTMLElement).dataset.userRef;
        const row = (b as HTMLElement).closest('tr') as HTMLTableRowElement | null;
        if (!userRef || !row || !tbody) return;

        if (openUserEditorId === userRef) {
          openUserEditorId = null;
          tbody.querySelectorAll('tr.user-editor-row').forEach((el) => el.remove());
          setUserEditActive(null);
          return;
        }

        openUserEditorId = userRef;
        void openUserEditorRow(panel, tbody, row, userRef, coaches, setUserEditActive);
      });
    });

    if (openUserEditorId) {
      const row = tbody?.querySelector(`tr.user-row button[data-user-ref="${openUserEditorId}"]`)?.closest('tr');
      if (row && tbody) {
        void openUserEditorRow(panel, tbody, row as HTMLTableRowElement, openUserEditorId, coaches, setUserEditActive);
      } else {
        openUserEditorId = null;
      }
    }
  }

  async function openUserEditorRow(
    panel: HTMLElement,
    tbody: Element,
    insertAfter: HTMLTableRowElement,
    userRef: string,
    coaches: { id: string; name: string }[],
    setUserEditActive: (activeId: string | null) => void,
  ): Promise<void> {
    tbody.querySelectorAll('tr.user-editor-row').forEach((el) => el.remove());
    const snap = await getDoc(doc(db, COL.users, userRef));
    if (!panel.isConnected) return;
    const x = snap.data() ?? {};
    const values: UserFormValues = {
      displayName: String(x.displayName ?? ''),
      email: String(x.email ?? ''),
      role: String(x.role ?? 'swimmer'),
      coachId: String(x.coachId ?? '').trim(),
      sportRank: String(x.sportRank ?? ''),
      city: String(x.city ?? ''),
    };
    const tr = document.createElement('tr');
    tr.className = 'user-editor-row';
    tr.dataset.userRef = userRef;
    const td = document.createElement('td');
    td.colSpan = 5;
    td.innerHTML = `
      <div class="card user-inline-editor">
        <h3>Правка пользователя</h3>
        ${userFormFieldsHtml(`ed-${userRef}`, coaches, values)}
        <p class="form-actions">
          <button type="button" class="primary" data-action="save">Сохранить</button>
          <button type="button" class="ghost" data-action="cancel">Закрыть</button>
        </p>
        <p class="err" data-ed="msg"></p>
      </div>
    `;
    tr.appendChild(td);
    insertAfter.insertAdjacentElement('afterend', tr);
    setUserEditActive(userRef);

    const closeEditor = (): void => {
      openUserEditorId = null;
      tr.remove();
      setUserEditActive(null);
    };

    tr.querySelector('[data-action="cancel"]')?.addEventListener('click', closeEditor);
    tr.querySelector('[data-action="save"]')?.addEventListener('click', async () => {
      const msg = tr.querySelector('[data-ed="msg"]') as HTMLElement;
      msg.textContent = '';
      const formValues = readUserForm(tr, `ed-${userRef}`);
      if (!formValues.displayName || !formValues.email || !formValues.role) {
        msg.textContent = 'ФИО, почта и роль — обязательные поля.';
        return;
      }
      try {
        await updateDoc(doc(db, COL.users, userRef), userPatchFromForm(formValues) as never);
        openUserEditorId = null;
        statusLine = 'Пользователь обновлён';
        await render();
      } catch (e) {
        msg.textContent = formatErr(e);
      }
    });
  }

  async function renderCatalog(panel: HTMLElement): Promise<void> {
    const snap = await getDocs(query(collection(db, COL.catalogExercises), orderBy('sortOrder')));
    if (!panel.isConnected) return;
    const rows: string[] = [];
    for (const d of snap.docs) {
      const x = d.data();
      rows.push(`
        <tr class="catalog-row" data-cat-ref="${escapeHtml(d.id)}">
          <td>${escapeHtml(String(x.title ?? ''))}</td>
          <td>${escapeHtml(String(catalogVolumeMeters(x)))}</td>
          <td>${escapeHtml(String(x.presetReps ?? ''))}×${escapeHtml(String(x.presetIntervalMeters ?? ''))} м</td>
          <td>${escapeHtml(String(x.sortOrder ?? ''))}</td>
          <td class="cell-actions">
            <button type="button" class="ghost sm-ed-cat" data-cat-ref="${escapeHtml(d.id)}">Правка</button>
            <button type="button" class="danger cat-del" data-cat-ref="${escapeHtml(d.id)}">Удалить</button>
          </td>
        </tr>
      `);
    }
    if (!panel.isConnected) return;
    panel.innerHTML = `
      <h2>Каталог упражнений</h2>
      <p class="panel-toolbar">
        <button type="button" class="primary" id="toggle-add-catalog">Добавить упражнение</button>
      </p>
      <div class="card collapsible-panel" id="add-catalog-card" hidden>
        <h3>Новое упражнение</h3>
        ${catalogFormFieldsHtml('new-cat', defaultCatalogValues())}
        <p class="form-actions">
          <button type="button" class="primary" id="c-add">Сохранить</button>
          <button type="button" class="ghost" id="cancel-add-catalog">Отмена</button>
        </p>
        <p id="c-msg" class="err"></p>
      </div>
      <div class="table-scroll">
        <table>
          <thead><tr><th>Название</th><th>Метры</th><th>Повторы</th><th>Порядок</th><th></th></tr></thead>
          <tbody id="catalog-tbody">${rows.join('') || '<tr><td colspan="5">Каталог пуст — добавьте упражнение</td></tr>'}</tbody>
        </table>
      </div>
    `;

    const tbody = panel.querySelector('#catalog-tbody');
    const addCatalogCard = panel.querySelector('#add-catalog-card') as HTMLElement;
    const toggleAddCatalogBtn = panel.querySelector('#toggle-add-catalog') as HTMLButtonElement;

    const setAddCatalogVisible = (visible: boolean): void => {
      addCatalogCard.hidden = !visible;
      toggleAddCatalogBtn.textContent = visible ? 'Скрыть форму' : 'Добавить упражнение';
    };

    panel.querySelector('#toggle-add-catalog')?.addEventListener('click', () => {
      setAddCatalogVisible(addCatalogCard.hidden);
    });
    panel.querySelector('#cancel-add-catalog')?.addEventListener('click', () => {
      setAddCatalogVisible(false);
    });

    panel.querySelector('#c-add')?.addEventListener('click', async () => {
      const msg = panel.querySelector('#c-msg') as HTMLElement;
      msg.textContent = '';
      const values = readCatalogForm(panel, 'new-cat');
      if (!values.id) {
        msg.textContent = 'Нужен код упражнения';
        return;
      }
      try {
        await setDoc(doc(db, COL.catalogExercises, values.id), catalogFirestorePayload(values));
        openCatalogEditorId = null;
        statusLine = 'Упражнение добавлено';
        await render();
      } catch (e) {
        msg.textContent = formatErr(e);
      }
    });

    const setCatalogEditActive = (activeId: string | null): void => {
      tbody?.querySelectorAll('.sm-ed-cat').forEach((btn) => {
        btn.classList.toggle('active', (btn as HTMLElement).dataset.catRef === activeId);
      });
    };

    panel.querySelectorAll('.cat-del').forEach((b) =>
      b.addEventListener('click', async () => {
        const id = (b as HTMLElement).dataset.catRef!;
        if (!confirm('Удалить упражнение?')) return;
        await deleteDoc(doc(db, COL.catalogExercises, id));
        if (openCatalogEditorId === id) openCatalogEditorId = null;
        statusLine = 'Удалено';
        await render();
      }),
    );

    tbody?.querySelectorAll('.sm-ed-cat').forEach((b) => {
      b.addEventListener('click', () => {
        const catRef = (b as HTMLElement).dataset.catRef;
        const row = (b as HTMLElement).closest('tr') as HTMLTableRowElement | null;
        if (!catRef || !row || !tbody) return;

        if (openCatalogEditorId === catRef) {
          openCatalogEditorId = null;
          tbody.querySelectorAll('tr.catalog-editor-row').forEach((el) => el.remove());
          setCatalogEditActive(null);
          return;
        }

        openCatalogEditorId = catRef;
        void openCatalogEditorRow(panel, tbody, row, catRef, setCatalogEditActive);
      });
    });

    if (openCatalogEditorId) {
      const row = tbody?.querySelector(`tr.catalog-row button[data-cat-ref="${openCatalogEditorId}"]`)?.closest('tr');
      if (row && tbody) {
        void openCatalogEditorRow(panel, tbody, row as HTMLTableRowElement, openCatalogEditorId, setCatalogEditActive);
      } else {
        openCatalogEditorId = null;
      }
    }
  }

  async function openCatalogEditorRow(
    panel: HTMLElement,
    tbody: Element,
    insertAfter: HTMLTableRowElement,
    catRef: string,
    setCatalogEditActive: (activeId: string | null) => void,
  ): Promise<void> {
    tbody.querySelectorAll('tr.catalog-editor-row').forEach((el) => el.remove());
    const snap = await getDoc(doc(db, COL.catalogExercises, catRef));
    if (!panel.isConnected) return;
    const values = catalogValuesFromDoc(snap.data() ?? {});
    const tr = document.createElement('tr');
    tr.className = 'catalog-editor-row';
    tr.dataset.catRef = catRef;
    const td = document.createElement('td');
    td.colSpan = 5;
    td.innerHTML = `
      <div class="card catalog-inline-editor">
        <h3>Правка упражнения</h3>
        ${catalogFormFieldsHtml(`ed-cat-${catRef}`, values, catRef)}
        <p class="form-actions">
          <button type="button" class="primary" data-action="save">Сохранить</button>
          <button type="button" class="ghost" data-action="cancel">Закрыть</button>
        </p>
        <p class="err" data-ed="msg"></p>
      </div>
    `;
    tr.appendChild(td);
    insertAfter.insertAdjacentElement('afterend', tr);
    setCatalogEditActive(catRef);

    const closeEditor = (): void => {
      openCatalogEditorId = null;
      tr.remove();
      setCatalogEditActive(null);
    };

    tr.querySelector('[data-action="cancel"]')?.addEventListener('click', closeEditor);
    tr.querySelector('[data-action="save"]')?.addEventListener('click', async () => {
      const msg = tr.querySelector('[data-ed="msg"]') as HTMLElement;
      msg.textContent = '';
      const formValues = readCatalogForm(tr, `ed-cat-${catRef}`);
      if (!formValues.title.trim()) {
        msg.textContent = 'Укажите название упражнения';
        return;
      }
      try {
        await updateDoc(doc(db, COL.catalogExercises, catRef), catalogFirestorePayload(formValues) as never);
        openCatalogEditorId = null;
        statusLine = 'Упражнение обновлено';
        await render();
      } catch (e) {
        msg.textContent = formatErr(e);
      }
    });
  }

  async function seedRankNormsRb2026(overwriteAll: boolean): Promise<void> {
    const snap = await getDocs(collection(db, COL.rankNorms));
    const existing = new Set(snap.docs.map((d) => d.id));
    const batch = writeBatch(db);
    let n = 0;
    for (const rid of RANK_IDS) {
      if (!overwriteAll && existing.has(rid)) {
        const cur = snap.docs.find((d) => d.id === rid)?.data();
        const entries = (cur?.entries as unknown[] | undefined) ?? [];
        if (entries.length > 0) continue;
      }
      const entries = RB_2026_RANK_NORMS[rid] ?? [];
      batch.set(
        doc(db, COL.rankNorms, rid),
        { rankId: rid, source: RB_2026_SOURCE, entries, updatedAt: serverTimestamp() },
        { merge: true },
      );
      n += 1;
    }
    if (n === 0) {
      statusLine = 'Все разряды уже заполнены';
      return;
    }
    await batch.commit();
    statusLine = `Загружено нормативов РБ 2026: ${n} разряд(ов)`;
  }

  function normsNeedSeed(byId: Map<string, Record<string, unknown>>): boolean {
    for (const rid of RANK_IDS) {
      const entries = (byId.get(rid)?.entries as unknown[] | undefined) ?? [];
      if (entries.length === 0) return true;
    }
    return byId.size === 0;
  }

  async function renderNorms(panel: HTMLElement): Promise<void> {
    let snap = await getDocs(collection(db, COL.rankNorms));
    if (!panel.isConnected) return;
    let byId = new Map(snap.docs.map((d) => [d.id, d.data()]));
    if (normsNeedSeed(byId)) {
      await seedRankNormsRb2026(false);
      snap = await getDocs(collection(db, COL.rankNorms));
      if (!panel.isConnected) return;
      byId = new Map(snap.docs.map((d) => [d.id, d.data()]));
    }

    const blocks = RANK_IDS.map((rid) => {
      const stored = (byId.get(rid)?.entries as NormEntry[] | undefined) ?? [];
      const entries = stored.length > 0 ? stored : (RB_2026_RANK_NORMS[rid] ?? []);
      const count = entries.length;
      return `
        <details class="norm-rank-block" ${rid === 'candidate_master' ? 'open' : ''}>
          <summary>
            <span class="norm-rank-title">${escapeHtml(RANK_LABELS[rid] ?? rid)}</span>
            <span class="muted norm-rank-meta">${count} норм · бассейны 25 и 50 м</span>
          </summary>
          <div class="norm-rank-body">
            ${normsTableHtml(rid, entries, escapeHtml)}
            <p class="norm-rank-actions">
              <button type="button" class="primary norm-save-rank" data-rid="${escapeHtml(rid)}">Сохранить разряд</button>
              <button type="button" class="ghost norm-reset-rank" data-rid="${escapeHtml(rid)}">Сбросить к эталону РБ 2026</button>
            </p>
            <p class="err norm-rank-msg" data-rid="${escapeHtml(rid)}" hidden></p>
          </div>
        </details>
      `;
    }).join('');

    if (!panel.isConnected) return;
    panel.innerHTML = `
      <h2>Нормативы по разрядам (РБ, 2026)</h2>
      <p style="margin:12px 0">
        <button type="button" class="primary" id="norms-seed-all">Обновить все разряды из эталона РБ 2026</button>
      </p>
      <div class="norms-list">${blocks}</div>
    `;

    panel.querySelector('#norms-seed-all')?.addEventListener('click', async () => {
      if (!window.confirm('Перезаписать нормативы всех разрядов эталоном РБ 2026?')) return;
      await seedRankNormsRb2026(true);
      await render();
    });

    panel.querySelectorAll('.norm-save-rank').forEach((btn) => {
      btn.addEventListener('click', async () => {
        const rid = (btn as HTMLElement).dataset.rid!;
        const block = (btn as HTMLElement).closest('.norm-rank-body');
        const table = block?.querySelector('table.norms-table') as HTMLTableElement | null;
        const msg = panel.querySelector(`.norm-rank-msg[data-rid="${rid}"]`) as HTMLElement | null;
        if (!table || !msg) return;
        msg.hidden = true;
        msg.textContent = '';
        const base = ((byId.get(rid)?.entries as NormEntry[] | undefined) ?? RB_2026_RANK_NORMS[rid] ?? []) as NormEntry[];
        const entries = readNormsFromTable(table, base);
        if (!entries) {
          msg.textContent = 'Проверьте формат времени во всех ячейках';
          msg.hidden = false;
          return;
        }
        await setDoc(
          doc(db, COL.rankNorms, rid),
          { rankId: rid, source: RB_2026_SOURCE, entries, updatedAt: serverTimestamp() },
          { merge: true },
        );
        statusLine = 'Сохранено: ' + (RANK_LABELS[rid] ?? rid);
        await render();
      });
    });

    panel.querySelectorAll('.norm-reset-rank').forEach((btn) => {
      btn.addEventListener('click', async () => {
        const rid = (btn as HTMLElement).dataset.rid!;
        const entries = RB_2026_RANK_NORMS[rid] ?? [];
        await setDoc(
          doc(db, COL.rankNorms, rid),
          { rankId: rid, source: RB_2026_SOURCE, entries, updatedAt: serverTimestamp() },
          { merge: true },
        );
        statusLine = 'Сброшено к эталону: ' + (RANK_LABELS[rid] ?? rid);
        await render();
      });
    });
  }

  onAuthStateChanged(auth, () => {
    void render();
  });

}
