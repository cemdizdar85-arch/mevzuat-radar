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
  // 08.09 Cem: "her konuya kaç soru yapsak, formül yapalım" — A = 3×kez · C = ders payı×10 deneme (kez oranında, en az 2) · E = kademe 1 (1 kez→1, 2+ kez→3) · BASILACAK = E (Cem elle değiştirir; koşucu bu sütunu okur)
  const dersKez = {}; for (const x of rows) { dersKez[x.ders] = (dersKez[x.ders] || 0) + x.kez; }
  const fA = x => 3 * x.kez, fC = x => Math.max(2, Math.round(((SINAV[x.ders] || 4) * 10) * x.kez / Math.max(1, dersKez[x.ders]))), fE = x => (x.kez >= 2 ? 3 : 1);
  ws.columns = [{ width: 26 }, { width: 46 }, { width: 12 }, { width: 12 }, { width: 14 }, { width: 14 }, { width: 8 }, { width: 8 }, { width: 12 }, { width: 12 }, { width: 24 }];
  const t = ws.addRow([`SGS — ne durumdayız (${tarih.slice(6, 8)}.${tarih.slice(4, 6)}.${tarih.slice(0, 4)}) · son 7 sınavda çıkan her konu bir satır`]); t.font = { bold: true, size: 13 };
  ws.addRow(['Sütunlar: SINAVDA = son 7 sınavda kaç kez çıktı · ESKİ = eskiden bastığımız · KURTARILABİLİR = kalıba sokulabilecek eski · BOŞ = eski kasada yok · Formül A = 3×kez · Formül C = ders payı×10 deneme · E (kademe 1) = 1 kez→1 soru, 2+ kez→3 soru · BASILACAK = koşucunun okuyacağı sayı (varsayılan E; sen değiştir) · KARAR = notun']);
  ws.addRow([]);
  const h = ws.addRow(['DERS', 'KONU', 'SINAVDA (kez)', 'ESKİ soru', 'KURTARILABİLİR', 'BOŞ mu?', 'Formül A', 'Formül C', 'E (kademe 1)', 'BASILACAK', 'KARAR']); h.font = { bold: true }; h.eachCell(c => { c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFDDEBF7' } }; c.border = { bottom: { style: 'medium' } }; });
  const dersler = Object.keys(SINAV).filter(d => rows.some(x => x.ders === d)).concat([...new Set(rows.map(x => x.ders))].filter(d => !SINAV[d]));
  for (const d of dersler) {
    const grp = rows.filter(x => x.ders === d).sort((a, b) => b.kez - a.kez || a.konu.localeCompare(b.konu, 'tr'));
    const bos = grp.filter(x => x.durum === 'YENİ BASIM').length; const kurtT = grp.reduce((s, x) => s + x.kurt, 0);
    const eT = grp.reduce((s, x) => s + fE(x), 0), aT = grp.reduce((s, x) => s + fA(x), 0);
    const b = ws.addRow([`${d}  —  sınavda ${SINAV[d] || '?'} soru · ${grp.length} konu · boş ${bos} · kademe 1: ${eT} soru · formül A: ${aT}`]); b.font = { bold: true, color: { argb: 'FFFFFFFF' } }; ws.mergeCells(b.number, 1, b.number, 11); b.getCell(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF305496' } };
    for (const x of grp) { const bosMu = x.durum === 'YENİ BASIM' ? 'BOŞ' : ''; const r = ws.addRow([d, x.konu, x.kez, x.eski, x.kurt, bosMu, fA(x), fC(x), fE(x), fE(x), '']); if (bosMu) { r.getCell(6).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8CBAD' } }; r.getCell(6).font = { bold: true }; } else { r.getCell(5).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE2EFDA' } }; } r.getCell(10).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFF2CC' } }; r.getCell(10).font = { bold: true }; [3, 4, 5, 7, 8, 9, 10].forEach(i => r.getCell(i).alignment = { horizontal: 'center' }); }
    ws.addRow([]);
  }
  const T = { e: rows.reduce((s, x) => s + fE(x), 0), a: rows.reduce((s, x) => s + fA(x), 0), c: rows.reduce((s, x) => s + fC(x), 0) };
  const tr = ws.addRow(['TOPLAM', `${rows.length} konu`, '', '', '', '', T.a, T.c, T.e, T.e, `≈${Math.round(T.e * 0.45)} USD (kademe 1) · ≈${Math.round(T.a * 0.45)} USD (A)`]); tr.font = { bold: true };
  ws.views = [{ state: 'frozen', ySplit: 4 }]; ws.autoFilter = { from: { row: 4, column: 1 }, to: { row: ws.rowCount, column: 11 } };
  const out = path.join(kok, 'sql-yerel', `SGS-TEK-SAYFA-${tarih}.xlsx`); await wb.xlsx.writeFile(out); console.log('yazildi: ' + out + ' · satir ' + ws.rowCount + ' · konu ' + rows.length);
})().catch(e => { console.error('HATA: ' + e.message); process.exit(1); });
