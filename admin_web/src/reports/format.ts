import { MOOD_LABELS, PHYSICAL_LABELS, RANK_LABELS, STROKE_LABELS } from './constants';

type TsLike = { toDate?: () => Date; seconds?: number };

export function tsToDate(v: unknown): Date | null {
  if (!v) return null;
  if (v instanceof Date) return v;
  const t = v as TsLike;
  if (typeof t.toDate === 'function') return t.toDate();
  if (typeof t.seconds === 'number') return new Date(t.seconds * 1000);
  return null;
}

export function formatDateRu(d: Date | null): string {
  if (!d) return '—';
  return d.toLocaleDateString('ru-BY', { day: '2-digit', month: '2-digit', year: 'numeric' });
}

export function formatDateTimeRu(d: Date | null): string {
  if (!d) return '—';
  return d.toLocaleString('ru-BY', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export function formatMeters(m: number): string {
  if (m >= 1000) return `${(m / 1000).toFixed(2)} км`;
  return `${Math.round(m)} м`;
}

export function formatKm(m: number): string {
  return `${(m / 1000).toFixed(2)} км`;
}

export function formatDuration(min: number, sec?: number): string {
  const total = sec ?? min * 60;
  const m = Math.floor(total / 60);
  const s = total % 60;
  return `${m}:${String(s).padStart(2, '0')}`;
}

export function formatCentiseconds(cs: number): string {
  if (cs <= 0) return '—';
  const totalSec = Math.floor(cs / 100);
  const hundredths = cs % 100;
  const m = Math.floor(totalSec / 60);
  const s = totalSec % 60;
  if (m > 0) return `${m}:${String(s).padStart(2, '0')},${String(hundredths).padStart(2, '0')}`;
  return `${s},${String(hundredths).padStart(2, '0')}`;
}

export function rankLabel(id: string): string {
  return (RANK_LABELS[id] ?? id) || '—';
}

export function strokeLabel(key: string): string {
  return (STROKE_LABELS[key] ?? key) || '—';
}

export function moodLabel(raw: unknown): string {
  if (raw == null || raw === '' || raw === '—') return '—';
  const idx = typeof raw === 'number' ? raw : parseInt(String(raw), 10);
  if (!Number.isNaN(idx) && idx >= 0 && idx < MOOD_LABELS.length) return MOOD_LABELS[idx]!;
  return String(raw);
}

export function physicalLabel(raw: unknown): string {
  const s = String(raw ?? '');
  if (PHYSICAL_LABELS[s]) return PHYSICAL_LABELS[s]!;
  if (s.includes('устав') || s.includes('tired')) return PHYSICAL_LABELS.tired!;
  if (s.includes('энерг') || s.includes('energy')) return PHYSICAL_LABELS.energy!;
  if (s.includes('норм') || s.includes('normal') || s.includes('стабил')) return PHYSICAL_LABELS.normal!;
  return s || '—';
}

export function inDateRange(d: Date | null, from: Date | null, to: Date | null): boolean {
  if (!d) return from == null && to == null;
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

export function parseInputDate(s: string): Date | null {
  const t = s.trim();
  if (!t) return null;
  const p = Date.parse(t);
  if (Number.isNaN(p)) return null;
  return new Date(p);
}

export function sheetNameSafe(name: string): string {
  return name.replace(/[\\/?*[\]:]/g, ' ').slice(0, 31);
}
