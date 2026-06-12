declare module 'pdfmake/build/pdfmake' {
  const pdfMake: {
    vfs: Record<string, string>;
    createPdf: (doc: Record<string, unknown>) => { download: (name: string) => void };
  };
  export default pdfMake;
}

declare module 'pdfmake/build/vfs_fonts' {
  const vfsFonts: { pdfMake?: { vfs: Record<string, string> }; vfs: Record<string, string> };
  export default vfsFonts;
}
