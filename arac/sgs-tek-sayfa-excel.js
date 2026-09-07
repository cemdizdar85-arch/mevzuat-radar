// SGS TEK SAYFA EXCEL (07.09 Cem: "excelde neye bakacağım anlamadım, tek sayfa yap")
// Girdi: sql-yerel/SINAV-SGS-<tarih>-HUNI.xlsx (KONU HUNI sayfası). Çıktı: sql-yerel/SGS-TEK-SAYFA-<tarih>.xlsx — TEK sayfa, 7 sütun.
const path = require('path'); const ExcelJS = require(path.join(process.env.EXCELJS_KOK, 'exceljs'));
const kok = path.join(__dirname, '..'); const [girdi, tarih] = process.argv.slice(2);
const SINAV = { 'Finansal Muhasebe': 26, 'Denetim': 16, 'Yabanci Dil': 10, 'Matematik': 8, 'Maliyet Muhasebesi': 8, 'Mali Tablolar Analizi': 8, 'Turkce': 7, 'Ekonomi': 6, 'Maliye': 6, 'Meslek Hukuku': 6, 'Is ve Sosyal Guvenlik Hukuku': 6, 'Vergi Hukuku': 6, 'Ticaret Hukuku': 6, 'Borclar Hukuku': 6, 'Ataturk Ilke ve Inkilap Tarihi': 5 };
(async () => {
  const wb0 = new ExcelJS.Workbook(); await wb0.xlsx.readFile(girdi); const ws0 = wb0.getWorksheet('KONU HUNI 07.09');
  const rows = [];
  for (let r = 4; r <= ws0.rowCount; r++) { const c = i => ws0.getRow(r).getCell(i).value; if (c(2) === null || c(2) === undefined || c(3) === null) continue; rows.push({ ders: String(c(1)).replace(/\*$/, ''), konu: String(c(2)), kez: Number(c(3)) || 0, eski: Number(c(5)) || 0, kurt: Number(c(7)) || 0, durum: String(c(9)) }); }
  const wb = new ExcelJS.Workbook(); const ws = wb.addWorksheet('SGS');
  ws.columns = [{ width: 26 }, { width: 46 }, { width: 12 }, { width: 12 }, { width: 14 }, { width: 14 }, { width: 24 }];
  const t = ws.addRow([`SGS — ne durumdayız (${tarih.slice(6, 8)}.${tarih.slice(4, 6)}.${tarih.slice(0, 4)}) · son 7 sınavda çıkan her konu bir satır`]); t.font = { bold: true, size: 13 };
  ws.addRow(['Sütunlar: SINAVDA = son 7 sınavda kaç kez çıktı · ESKİ = eskiden bastığımız soru · KURTARILABİLİR = kalıba sokulabilecek eski soru · BOŞ = eski kasada hiç yok, yeni basılacak · KARAR = sen yazarsın (bas / geç / önce eski)']);
  ws.addRow([]);
  const h = ws.addRow(['DERS', 'KONU', 'SINAVDA (kez)', 'ESKİ soru', 'KURTARILABİLİR', 'BOŞ mu?', 'KARAR']); h.font = { bold: true }; h.eachCell(c => { c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFDDEBF7' } }; c.border = { bottom: { style: 'medium' } }; });
  const dersler = Object.keys(SINAV).filter(d => rows.some(x => x.ders === d)).concat([...new Set(rows.map(x => x.ders))].filter(d => !SINAV[d]));
  for (const d of dersler) {
    const grp = rows.filter(x => x.ders === d).sort((a, b) => b.kez - a.kez || a.konu.localeCompare(b.konu, 'tr'));
    const bos = grp.filter(x => x.durum === 'YENİ BASIM').length; const kurtT = grp.reduce((s, x) => s + x.kurt, 0);
    const b = ws.addRow([`${d}  —  sınavda ${SINAV[d] || '?'} soru · ${grp.length} konu · boş ${bos}`]); b.font = { bold: true, color: { argb: 'FFFFFFFF' } }; ws.mergeCells(b.number, 1, b.number, 7); b.getCell(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF305496' } };
    for (const x of grp) { const bosMu = x.durum === 'YENİ BASIM' ? 'BOŞ' : ''; const r = ws.addRow([d, x.konu, x.kez, x.eski, x.kurt, bosMu, '']); if (bosMu) { r.getCell(6).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8CBAD' } }; r.getCell(6).font = { bold: true }; } else { r.getCell(5).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE2EFDA' } }; } [3, 4, 5].forEach(i => r.getCell(i).alignment = { horizontal: 'center' }); }
    ws.addRow([]);
  }
  ws.views = [{ state: 'frozen', ySplit: 4 }]; ws.autoFilter = { from: { row: 4, column: 1 }, to: { row: ws.rowCount, column: 7 } };
  const out = path.join(kok, 'sql-yerel', `SGS-TEK-SAYFA-${tarih}.xlsx`); await wb.xlsx.writeFile(out); console.log('yazildi: ' + out + ' · satir ' + ws.rowCount + ' · konu ' + rows.length);
})().catch(e => { console.error('HATA: ' + e.message); process.exit(1); });
