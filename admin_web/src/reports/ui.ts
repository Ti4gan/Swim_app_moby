import type { Firestore } from 'firebase/firestore';
import { REPORT_DEFS, type ReportTypeId } from './constants';
import { loadUsers } from './data';
import { downloadExcel } from './export_excel';
import { downloadPdf } from './export_pdf';
import { parseInputDate } from './format';
import { buildReportSheets } from './generators';
import type { ReportFilters } from './types';

export type ReportsUiHelpers = {
  escapeHtml: (s: string) => string;
  onStatus: (line: string) => void;
};

export async function renderReports(
  panel: HTMLElement,
  db: Firestore,
  helpers: ReportsUiHelpers,
): Promise<void> {
  const { escapeHtml, onStatus } = helpers;
  onStatus('');

  const users = await loadUsers(db);
  if (!panel.isConnected) return;

  const swimmers = users.filter((u) => u.role === 'swimmer' && (u.displayName || u.email));
  swimmers.sort((a, b) => a.displayName.localeCompare(b.displayName, 'ru'));

  const coaches = users.filter((u) => u.role === 'coach' && u.displayName);
  coaches.sort((a, b) => a.displayName.localeCompare(b.displayName, 'ru'));

  const swimmerOptions = [
    '<option value="">— выберите спортсмена —</option>',
    ...swimmers.map(
      (s) =>
        `<option value="${escapeHtml(s.id)}">${escapeHtml(s.displayName || s.email)}${s.coachName ? ` · ${escapeHtml(s.coachName)}` : ''}</option>`,
    ),
  ].join('');

  const coachFilterOptions = [
    '<option value="">Все тренеры</option>',
    ...coaches.map(
      (c) => `<option value="${escapeHtml(c.id)}">${escapeHtml(c.displayName)}</option>`,
    ),
  ].join('');

  const reportBlocks = REPORT_DEFS.map((r) => {
    const extra =
      r.id === 'athlete_goals_comparison'
        ? `
        <label class="filter-field">Спортсмен
          <select class="rep-athlete" data-report="${escapeHtml(r.id)}">${swimmerOptions}</select>
        </label>`
        : `
        <label class="filter-field">Тренер (необязательно)
          <select class="rep-coach-filter" data-report="${escapeHtml(r.id)}">${coachFilterOptions}</select>
        </label>`;

    return `
      <div class="card report-block" data-report-id="${escapeHtml(r.id)}">
        <h3 class="reports-h3">${escapeHtml(r.title)}</h3>
        <p class="sub">${escapeHtml(r.hint)}</p>
        <div class="grid2" style="margin-top:12px">
          <label>Дата с<br/><input type="date" class="rep-from" data-report="${escapeHtml(r.id)}" /></label>
          <label>Дата по<br/><input type="date" class="rep-to" data-report="${escapeHtml(r.id)}" /></label>
        </div>
        ${extra}
        <p class="sub" style="margin:8px 0 0">Пустые даты — без ограничения по периоду.</p>
        <p style="margin-top:16px">
          <button type="button" class="primary rep-export" data-report="${escapeHtml(r.id)}" data-fmt="xlsx">Excel (.xlsx)</button>
          <button type="button" class="ghost rep-export" data-report="${escapeHtml(r.id)}" data-fmt="pdf" style="margin-left:8px">PDF</button>
        </p>
      </div>`;
  }).join('');

  panel.innerHTML = `
    <h2>Отчёты</h2>
    <div class="reports-stack">${reportBlocks}</div>
    <p id="rep-progress" class="sub" style="margin-top:12px"></p>
    <p id="rep-err" class="err"></p>
  `;

  const progressEl = panel.querySelector('#rep-progress') as HTMLElement;
  const errEl = panel.querySelector('#rep-err') as HTMLElement;

  const readFilters = (reportId: ReportTypeId): ReportFilters => {
    const fromEl = panel.querySelector(`.rep-from[data-report="${reportId}"]`) as HTMLInputElement;
    const toEl = panel.querySelector(`.rep-to[data-report="${reportId}"]`) as HTMLInputElement;
    const athleteEl = panel.querySelector(
      `.rep-athlete[data-report="${reportId}"]`,
    ) as HTMLSelectElement | null;
    const coachEl = panel.querySelector(
      `.rep-coach-filter[data-report="${reportId}"]`,
    ) as HTMLSelectElement | null;
    return {
      dateFrom: parseInputDate(fromEl?.value ?? ''),
      dateTo: parseInputDate(toEl?.value ?? ''),
      coachId: coachEl?.value.trim() ?? '',
      athleteIds: [],
      athleteId: athleteEl?.value.trim() ?? '',
    };
  };

  panel.querySelectorAll('.rep-export').forEach((btn) => {
    btn.addEventListener('click', async () => {
      errEl.textContent = '';
      progressEl.textContent = '';
      const reportId = (btn as HTMLElement).dataset.report as ReportTypeId;
      const fmt = (btn as HTMLElement).dataset.fmt ?? 'xlsx';
      const filters = readFilters(reportId);

      if (reportId === 'athlete_goals_comparison' && !filters.athleteId) {
        errEl.textContent = 'Выберите спортсмена для сравнительного отчёта';
        return;
      }

      const htmlBtn = btn as HTMLButtonElement;
      htmlBtn.disabled = true;
      try {
        progressEl.textContent = 'Формирование отчёта…';
        const sheets = await buildReportSheets(
          db,
          reportId,
          { users, filters, generatedAt: new Date() },
          (msg) => {
            progressEl.textContent = msg;
          },
        );
        if (sheets.length === 0) {
          errEl.textContent = 'Нет данных для отчёта';
          return;
        }
        const stamp = new Date().toISOString().slice(0, 10);
        const base =
          reportId === 'athlete_goals_comparison'
            ? `swimflow_athlete_${filters.athleteId.slice(0, 8)}_${stamp}`
            : `swimflow_coaches_${stamp}`;
        if (fmt === 'pdf') {
          downloadPdf(sheets, base);
        } else {
          downloadExcel(sheets, base);
        }
        progressEl.textContent = `Готово · ${fmt.toUpperCase()} · ${sheets.length} лист(ов)`;
        onStatus('Отчёт сформирован');
      } catch (e) {
        errEl.textContent = String(e);
      } finally {
        htmlBtn.disabled = false;
      }
    });
  });
}
