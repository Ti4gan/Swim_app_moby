import pdfMake from 'pdfmake/build/pdfmake';
import pdfFonts from 'pdfmake/build/vfs_fonts';
import type { ReportSheet } from './types';

pdfMake.vfs = pdfFonts.pdfMake?.vfs ?? pdfFonts.vfs;

type PdfContent = Record<string, unknown>;

const tableLayout = {
  fillColor: (rowIndex: number) => {
    if (rowIndex === 0) return '#0b6bcb';
    return rowIndex % 2 === 0 ? '#f6f7f9' : null;
  },
  hLineColor: () => '#e1e4e8',
  vLineColor: () => '#e1e4e8',
  paddingLeft: () => 6,
  paddingRight: () => 6,
  paddingTop: () => 4,
  paddingBottom: () => 4,
};

export function downloadPdf(sheets: ReportSheet[], fileBase: string): void {
  const content: PdfContent[] = [];

  sheets.forEach((sheet, si) => {
    if (si > 0) {
      content.push({ text: '', pageBreak: 'before' });
    }
    content.push({
      text: sheet.title,
      style: 'h1',
      margin: [0, 0, 0, 8],
    });
    if (sheet.meta?.length) {
      content.push({
        ul: sheet.meta.map((m) => `${m.label}: ${m.value}`),
        style: 'meta',
        margin: [0, 0, 0, 10],
      });
    }
    const body = [
      sheet.headers.map((h) => ({ text: h, style: 'th', color: '#ffffff' })),
      ...sheet.rows.map((row) => row.map((c) => String(c))),
    ];
    content.push({
      table: {
        headerRows: 1,
        widths: sheet.headers.map(() => '*'),
        body,
      },
      layout: tableLayout,
      margin: [0, 0, 0, 12],
    });
  });

  const doc = {
    pageOrientation: 'landscape' as const,
    pageMargins: [28, 36, 28, 40] as [number, number, number, number],
    defaultStyle: { font: 'Roboto', fontSize: 8 },
    styles: {
      h1: { fontSize: 14, bold: true, color: '#1a1d21' },
      meta: { fontSize: 8, color: '#5c6570' },
      th: { bold: true, fontSize: 8 },
    },
    footer: (currentPage: number, pageCount: number) => ({
      columns: [
        { text: 'SwimFlow · админ-отчёт', style: 'meta', alignment: 'left' },
        { text: `${currentPage} / ${pageCount}`, alignment: 'right', style: 'meta' },
      ],
      margin: [28, 0, 28, 0],
    }),
    content,
  };

  const stamp = new Date().toISOString().slice(0, 10);
  pdfMake.createPdf(doc).download(`${fileBase}_${stamp}.pdf`);
}
