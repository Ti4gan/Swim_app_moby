import type { NormEntry } from './rank_norms_rb_2026';

export const DISCIPLINE_LABELS: Record<string, string> = {
  free: 'Вольный стиль',
  breast: 'Брасс',
  fly: 'Баттерфляй',
  back: 'На спине',
  im: 'Комплекс',
};

export function formatTimeRu(sec: number): string {
  if (!Number.isFinite(sec) || sec < 0) return '';
  const totalCs = Math.round(sec * 100);
  const cs = totalCs % 100;
  const totalSec = Math.floor(totalCs / 100);
  const s = totalSec % 60;
  const m = Math.floor(totalSec / 60);
  const frac = cs.toString().padStart(2, '0');
  if (m > 0) return `${m}:${s.toString().padStart(2, '0')},${frac}`;
  return `${s},${frac}`;
}

export function parseTimeRu(raw: string): number | null {
  const s = raw.trim().replace(/\s/g, '').replace('.', ',');
  if (!s) return null;
  if (s.includes(':')) {
    const [minPart, secPart] = s.split(':', 2);
    const min = Number.parseInt(minPart, 10);
    const sec = Number.parseFloat(secPart.replace(',', '.'));
    if (!Number.isFinite(min) || !Number.isFinite(sec)) return null;
    return min * 60 + sec;
  }
  const sec = Number.parseFloat(s.replace(',', '.'));
  return Number.isFinite(sec) ? sec : null;
}

export function sortNormEntries(entries: NormEntry[]): NormEntry[] {
  const order = ['free', 'breast', 'fly', 'back', 'im'];
  return [...entries].sort((a, b) => {
    const pa = a.poolLengthMeters - b.poolLengthMeters;
    if (pa !== 0) return pa;
    const da = order.indexOf(a.discipline) - order.indexOf(b.discipline);
    if (da !== 0) return da;
    return a.distanceMeters - b.distanceMeters;
  });
}

export function rankOptionsHtml(
  rankIds: string[],
  labels: Record<string, string>,
  selectedId: string,
): string {
  const opts = ['<option value="">— не указан —</option>'];
  for (const id of rankIds) {
    const sel = id === selectedId ? ' selected' : '';
    const label = labels[id] ?? id;
    opts.push(`<option value="${id.replace(/"/g, '&quot;')}"${sel}>${label.replace(/</g, '&lt;')}</option>`);
  }
  return opts.join('');
}

export function normsTableHtml(rankId: string, entries: NormEntry[], escapeHtml: (s: string) => string): string {
  const sorted = sortNormEntries(entries);
  if (sorted.length === 0) {
    return '<p class="muted">Нормативы не заданы</p>';
  }
  const rows = sorted
    .map((en, idx) => {
      const disc = DISCIPLINE_LABELS[en.discipline] ?? en.discipline;
      return `
        <tr data-norm-idx="${idx}">
          <td>${en.poolLengthMeters} м</td>
          <td>${escapeHtml(disc)}</td>
          <td>${en.distanceMeters}</td>
          <td><input type="text" class="norm-time" data-gender="m" value="${escapeHtml(formatTimeRu(en.menTimeSec))}" inputmode="decimal" /></td>
          <td><input type="text" class="norm-time" data-gender="w" value="${escapeHtml(formatTimeRu(en.womenTimeSec))}" inputmode="decimal" /></td>
        </tr>
      `;
    })
    .join('');
  return `
    <table class="norms-table" data-rank-id="${escapeHtml(rankId)}">
      <thead>
        <tr>
          <th>Бассейн</th>
          <th>Стиль</th>
          <th>Дистанция, м</th>
          <th>Юноши / мужчины</th>
          <th>Девушки / женщины</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  `;
}

export function readNormsFromTable(table: HTMLTableElement, baseEntries: NormEntry[]): NormEntry[] | null {
  const sorted = sortNormEntries(baseEntries);
  const trs = [...table.querySelectorAll('tbody tr')];
  if (trs.length !== sorted.length) return null;
  const out: NormEntry[] = [];
  for (let i = 0; i < trs.length; i++) {
    const base = sorted[i];
    const tr = trs[i];
    const menIn = tr.querySelector('input[data-gender="m"]') as HTMLInputElement | null;
    const womenIn = tr.querySelector('input[data-gender="w"]') as HTMLInputElement | null;
    const men = parseTimeRu(menIn?.value ?? '');
    const women = parseTimeRu(womenIn?.value ?? '');
    if (men == null || women == null) return null;
    out.push({
      discipline: base.discipline,
      distanceMeters: base.distanceMeters,
      poolLengthMeters: base.poolLengthMeters,
      menTimeSec: men,
      womenTimeSec: women,
    });
  }
  return out;
}
