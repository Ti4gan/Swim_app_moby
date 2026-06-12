import * as XLSX from 'xlsx';
import { sheetNameSafe } from './format';
import type { ReportSheet } from './types';

export function downloadExcel(sheets: ReportSheet[], fileBase: string): void {
  const wb = XLSX.utils.book_new();
  const used = new Set<string>();

  for (const sheet of sheets) {
    let name = sheetNameSafe(sheet.name);
    let n = 1;
    while (used.has(name)) {
      n += 1;
      name = sheetNameSafe(`${sheet.name} ${n}`);
    }
    used.add(name);

    const aoa: (string | number)[][] = [];
    if (sheet.meta?.length) {
      for (const m of sheet.meta) {
        aoa.push([m.label, m.value]);
      }
      aoa.push([]);
    }
    aoa.push([sheet.title]);
    aoa.push([]);
    aoa.push(sheet.headers);
    for (const row of sheet.rows) {
      aoa.push(row);
    }

    const ws = XLSX.utils.aoa_to_sheet(aoa);
    const colWidths = sheet.headers.map((_, ci) => {
      let max = sheet.headers[ci]?.length ?? 10;
      for (const row of sheet.rows) {
        const cell = String(row[ci] ?? '');
        if (cell.length > max) max = cell.length;
      }
      return { wch: Math.min(Math.max(max + 2, 8), 48) };
    });
    ws['!cols'] = colWidths;
    XLSX.utils.book_append_sheet(wb, ws, name);
  }

  const stamp = new Date().toISOString().slice(0, 10);
  XLSX.writeFile(wb, `${fileBase}_${stamp}.xlsx`);
}
