// SGS EXCEL DOLDURUCU (07.09.2026 gece, Cem: "bir excelimiz vardı, onu doldursan, ne durumdayız SGS ordan konuşalım")
// Girdi : sql-yerel/SINAV-SGS-<eski>.xlsx (3-KONULAR sayfası: Resmî ders | Bizim ders | Arşiv ders | Konu | Bizim soru | Çıkmış soru | Dönem | Durum | …)
//         veri/fabrika/eski-sgs-dump-<tarih>.json (soru_havuzu SGS dökümü) · veri/yayin-havuzu-olcum.json (kapı-temiz idler)
//         veri/fabrika/eski-sgs-huni-<tarih>.json (aday idler) · veri/sgs-analiz.json (son 7 dönem) · veri/sinav/kaydir-secim/parti30-secim.json (v29 basılan)
// Çıktı : sql-yerel/SINAV-SGS-<tarih>-HUNI.xlsx — 3-KONULAR'a 6 yeni sütun + "0-DURUM 07.09" ders özeti sayfası. Eski dosyaya dokunulmaz.
// Eşleme konu düzeyinde ve BİREBİR (ASCII küçük harf); kök eşleşmesi kullanılmaz → sayılar tutucu (az gösterir), şişirmez.
// Çalıştırma: EXCELJS_KOK=<node_modules yolu> node arac/sgs-excel-doldur.js <eski.xlsx> <dump.json> <huni.json> <tarih>
const path = require('path'), fs = require('fs');
const ExcelJS = require(path.join(process.env.EXCELJS_KOK, 'exceljs'));
const kok = path.join(__dirname, '..');
const oku = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, ''));   // PS 5.1 bazı JSON'ları BOM'lu yazıyor
const [eskiXlsx, dumpYol, huniYol, tarih] = process.argv.slice(2);
const PENCERE = 7;
const katla = s => String(s || '').replace(/İ/g, 'i').replace(/I/g, 'i').replace(/ı/g, 'i').replace(/[ĞğĝĜ]/g, 'g').replace(/[Üü]/g, 'u').replace(/[Şş]/g, 's').replace(/[Öö]/g, 'o').replace(/[Çç]/g, 'c').toLowerCase().replace(/\s+/g, ' ').trim();
const SINAV_SORU = { 'Turkce': 7, 'Matematik': 8, 'Ataturk Ilke ve Inkilap Tarihi': 5, 'Ataturk Ilkeleri ve Inkilap Tarihi': 5, 'Yabanci Dil': 10, 'Finansal Muhasebe': 26, 'Maliyet Muhasebesi': 8, 'Mali Tablolar Analizi': 8, 'Denetim': 16, 'Ekonomi': 6, 'Maliye': 6, 'Meslek Hukuku': 6, 'Is ve Sosyal Guvenlik Hukuku': 6, 'Vergi Hukuku': 6, 'Ticaret Hukuku': 6, 'Borclar Hukuku': 6 };
(async () => {
  // --- girdiler
  const dump = oku(dumpYol);
  const olc = oku(path.join(kok, 'veri/yayin-havuzu-olcum.json'));
  const temiz = new Set((olc.idler || []).map(x => typeof x === 'string' ? x : x.id));
  const huni = oku(huniYol);
  const aday = new Set((huni.adayIdler || []).map(x => x.id));
  const an = oku(path.join(kok, 'veri/sgs-analiz.json'));
  const sonD = [...an.donemler].sort((a, b) => parseInt(String(b.donem).replace('/', '')) - parseInt(String(a.donem).replace('/', ''))).slice(0, PENCERE);
  const pencereKonu = new Map(); // katla(konu) -> Set(dönem)
  for (const d of sonD) for (const k of Object.keys(d.konuSayim || {})) { const lab = katla(k.replace(/^[^|]*\|/, '')); if (!pencereKonu.has(lab)) pencereKonu.set(lab, new Set()); pencereKonu.get(lab).add(d.donem); }
  let v29 = []; try { v29 = oku(path.join(kok, 'veri/sinav/kaydir-secim/parti30-secim.json')); } catch (e) {}
  const v29Konu = new Map(); for (const s of v29) { const kk = katla(s.konu); v29Konu.set(kk, (v29Konu.get(kk) || 0) + 1); }
  // --- kasa konusu bazında sayımlar (birebir)
  const kasaKonu = new Map(); // katla(konu) -> {kasa, temiz, aday, dersler:Set}
  for (const s of dump) { const kk = katla(s.konu); if (!kasaKonu.has(kk)) kasaKonu.set(kk, { kasa: 0, temiz: 0, aday: 0, dersler: new Set() }); const o = kasaKonu.get(kk); o.kasa++; if (temiz.has(s.id)) o.temiz++; if (aday.has(s.id)) o.aday++; o.dersler.add(s.ders); }
  // --- excel
  const wb = new ExcelJS.Workbook(); await wb.xlsx.readFile(eskiXlsx);
  const ws = wb.getWorksheet('3-KONULAR'); if (!ws) throw new Error('3-KONULAR sayfası yok');
  const hdr = {}; ws.getRow(1).eachCell((c, i) => { hdr[katla(c.value)] = i; });
  const col = ad => { const k = Object.keys(hdr).find(h => h.startsWith(katla(ad))); if (!k) throw new Error('sütun yok: ' + ad); return hdr[k]; };
  const cDers = col('Resmî ders'), cKonu = col('Konu'), cBizim = col('Bizim soru'), cCikmis = col('Çıkmış soru'), cDonem = col('Dönem'), cDurum = col('Durum');
  const yeni = ['Son 7 dönemde (kez)', 'Eski soru kapı-temiz (birebir konu)', 'Kalıba ADAY (eski; kök eşleşmeli)', 'v29 basılan (07.09)', 'DURUM 07.09', 'Öncelik (dönem×sınav ağırlığı)', 'DERS 07.09 (düzeltilmiş; * sezgisel)'];
  const c0 = ws.columnCount + 1; yeni.forEach((y, i) => { const c = ws.getCell(1, c0 + i); c.value = y; c.font = { bold: true }; c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFF2CC' } }; });
  const ozet = new Map(); // ders -> sayaçlar
  const oz = d => { if (!ozet.has(d)) ozet.set(d, { pencereKonu: 0, adayVar: 0, bos: 0, pencereDisi: 0, eskiAday: 0, v29: 0, kasa: 0 }); return ozet.get(d); };
  for (let r = 2; r <= ws.rowCount; r++) {
    const row = ws.getRow(r); const dersExcel = String(row.getCell(cDers).value || ''); const konu = katla(row.getCell(cKonu).value); if (!konu) continue;
    const pk = pencereKonu.get(konu); const pen = pk ? pk.size : 0;
    // 07.09 Cem: köprü, arşivin "Muhasebe"/"Hukuk" bölümünü yerleştiremediği konuları toptan FMuh/Ticaret'e yazıyordu → pencere konusunda huni'nin ders ataması kullanılır
    const dersHuni = (pen > 0 && huni.etiketDers && huni.etiketDers[konu]) ? String(huni.etiketDers[konu]) : '';
    const ders = dersHuni ? dersHuni.replace(/\*$/, '') : dersExcel;
    const kk = Object.assign({}, kasaKonu.get(konu) || { kasa: 0, temiz: 0, aday: 0 });
    // kök eşleşmeli aday (huni ile aynı ölçüm): pencere etiketine kök benzerliğiyle bağlanan eski sorular; birebir sayıdan büyükse o alınır
    const kokAday = (huni.etiketAdaySay && huni.etiketAdaySay[konu]) || 0; if (kokAday > kk.aday) kk.aday = kokAday;
    const v = v29Konu.get(konu) || 0;
    let durum; if (pen === 0) durum = 'PENCERE DIŞI (son 7 dönemde çıkmadı)'; else if (kk.aday > 0 || v > 0) durum = 'KALIBA ADAY VAR'; else if (kk.temiz > 0) durum = 'ESKİ VAR, KAYNAK/PENCERE TUTMADI'; else durum = 'YENİ BASIM';
    const agir = SINAV_SORU[ders] || 1; const oncelik = pen * agir;
    [pen, kk.temiz, kk.aday, v, durum, oncelik, (dersHuni || dersExcel)].forEach((val, i) => { row.getCell(c0 + i).value = val; });
    if (durum === 'YENİ BASIM') row.getCell(c0 + 4).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8CBAD' } };
    if (durum === 'KALIBA ADAY VAR') row.getCell(c0 + 4).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFC6EFCE' } };
    const o = oz(ders); o.kasa += kk.kasa; if (pen > 0) { o.pencereKonu++; if (durum === 'KALIBA ADAY VAR') o.adayVar++; else if (durum === 'YENİ BASIM') o.bos++; } else o.pencereDisi++; o.eskiAday += kk.aday; o.v29 += v;
    row.commit();
  }
  // --- ders özeti sayfası (en başa)
  const wo = wb.addWorksheet('0-DURUM 07.09'); wb.worksheets.unshift(wb.worksheets.pop()); // sıraya al
  wo.addRow([`SGS DURUM — ${tarih} gece · huni + pencere (son ${PENCERE} dönem: ${sonD.map(d => d.donem).join(', ')}) · konu eşlemesi BİREBİR (tutucu)`]);
  wo.addRow([]);
  const bas = wo.addRow(['Ders', 'Sınavda soru', 'Pencere konusu', 'Kalıba aday var', 'Yeni basım (boş)', 'Eski aday soru (tekil)', 'v29 basılan', '5 deneme hedefi', 'Not']);
  bas.font = { bold: true };
  const derslerSira = Object.keys(SINAV_SORU).filter(d => ozet.has(d)).sort((a, b) => SINAV_SORU[b] - SINAV_SORU[a]);
  let T = { s: 0, p: 0, a: 0, b: 0, e: 0, v: 0, h: 0 };
  // ders bazlı eski aday = huni'nin TEKİL sayımı (bir soru birden çok etikete uyabilir; konu satırlarının toplamı şişer, ders toplamı tekil olmalı)
  const huniDers = new Map((huni.ders || []).map(x => [String(x.ders), Number(x.aday) || 0]));
  for (const d of derslerSira) { const o = ozet.get(d); o.eskiAday = huniDers.has(d) ? huniDers.get(d) : (huniDers.get(d.replace('Ataturk Ilke ve', 'Ataturk Ilkeleri ve')) ?? o.eskiAday); const hedef = SINAV_SORU[d] * 5; let not = ''; if (o.eskiAday < hedef / 2) not = 'eski aday yetmez → yeni basım ağır'; if (d === 'Ekonomi' || d === 'Maliye') not = 'kaynak damgası yok → teori notu bağlanmadan basım tıkanır'; if (['Turkce', 'Matematik', 'Yabanci Dil', 'Ataturk Ilke ve Inkilap Tarihi'].includes(d)) not = (not ? not + ' · ' : '') + 'genel kültür: kalıp uyumu ölçülmedi (pilot)'; wo.addRow([d, SINAV_SORU[d], o.pencereKonu, o.adayVar, o.bos, o.eskiAday, o.v29, hedef, not]); T.s += SINAV_SORU[d]; T.p += o.pencereKonu; T.a += o.adayVar; T.b += o.bos; T.e += o.eskiAday; T.v += o.v29; T.h += hedef; }
  const tr = wo.addRow(['TOPLAM', T.s, T.p, T.a, T.b, T.e, T.v, T.h, '']); tr.font = { bold: true };
  wo.addRow([]); wo.addRow(['Okuma: Pencere konusu = son 7 dönemde çıkan konu. Kalıba aday var = eski kasada kapı-temiz + damgalı + pencerede soru var. Yeni basım = pencerede çıkmış ama eski kasada aday yok. Eski aday soru = yarı yenilemeye girecek eski soru sayısı (kalıp kapıları ayrıca eler). v29 basılan = 07.09 parti-30 sayfasındaki sorular.']);
  wo.addRow(['3-KONULAR sayfasında her konunun karşısına 6 yeni sütun eklendi (sarı başlık): son 7 dönem sayısı, kapı-temiz eski soru, kalıba aday, v29 basılan, DURUM 07.09 (yeşil = aday var, kırmızı = yeni basım), öncelik = dönem × sınavdaki soru sayısı.']);
  wo.columns.forEach((c, i) => { c.width = i === 0 ? 34 : (i === 8 ? 70 : 16); });
  // --- KONU HUNİ sayfası (07.09 Cem: "tüm derslere böyle yap: sınavda bu kadar çıkıyor, eskiden bastığımız soru, ne kadarını kurtarabiliyorsun")
  // Satır = son 7 dönemde çıkan konu (802). Sayılar kök eşleşmeli (huni ile aynı ölçüm): bir eski soru birden çok konuya sayılabilir → ders toplamı için 0-DURUM'daki tekil sayı geçerlidir.
  const wk = wb.addWorksheet('KONU HUNI 07.09'); wb.worksheets.unshift(wb.worksheets.pop()); wb.worksheets.unshift(wb.worksheets.pop()); // 0-DURUM'un hemen ardına gelsin
  wk.addRow([`KONU HUNİSİ — son ${PENCERE} dönem (${sonD.map(d => d.donem).join(', ')}) · her satır sınavda çıkan bir konu · sayılar kök eşleşmeli (tutucu değil, bir soru birden çok konuya sayılabilir)`]);
  wk.addRow([]);
  const kb = wk.addRow(['Ders 07.09', 'Konu (arşiv etiketi)', 'Sınavda çıktı (son 7 dönem, kez)', 'Çıkmış soru (2015+)', 'Eskiden bastığımız (kasa)', 'Kapıdan geçen', 'KURTARILABİLİR (kalıba aday)', 'v29 basılan', 'DURUM 07.09', 'Öncelik', 'KARAR (Cem)']); kb.font = { bold: true };
  const satirlar = [];
  for (let r = 2; r <= ws.rowCount; r++) { const row = ws.getRow(r); const pen = Number(row.getCell(c0).value) || 0; if (!pen) continue; const konu = katla(row.getCell(cKonu).value); const dersH = String(row.getCell(c0 + 6).value || row.getCell(cDers).value); const dersT = dersH.replace(/\*$/, '');
    satirlar.push({ ders: dersH, dersT, konu: String(row.getCell(cKonu).value), pen, cikmis: Number(row.getCell(cCikmis).value) || 0, kasa: (huni.etiketKasaSay && huni.etiketKasaSay[konu]) || 0, temiz: (huni.etiketTemizSay && huni.etiketTemizSay[konu]) || 0, aday: Number(row.getCell(c0 + 2).value) || 0, v29: Number(row.getCell(c0 + 3).value) || 0, durum: String(row.getCell(c0 + 4).value), oncelik: Number(row.getCell(c0 + 5).value) || 0 }); }
  const gorulen = new Set(); const tekil = satirlar.filter(x => { const k = x.dersT + '|' + katla(x.konu); if (gorulen.has(k)) return false; gorulen.add(k); return true; });
  tekil.sort((a, b) => (SINAV_SORU[b.dersT] || 0) - (SINAV_SORU[a.dersT] || 0) || a.dersT.localeCompare(b.dersT, 'tr') || b.pen - a.pen || a.konu.localeCompare(b.konu, 'tr'));
  let sonDers = ''; for (const x of tekil) { if (x.dersT !== sonDers) { sonDers = x.dersT; const grp = tekil.filter(y => y.dersT === sonDers); const ara = wk.addRow([`${sonDers} — sınavda ${SINAV_SORU[sonDers] || '?'} soru · pencerede ${grp.length} konu · aday var ${grp.filter(y => y.durum === 'KALIBA ADAY VAR').length} · boş ${grp.filter(y => y.durum === 'YENİ BASIM').length}`]); ara.font = { bold: true }; ara.getCell(1).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFDDEBF7' } }; }
    const rr = wk.addRow([x.ders, x.konu, x.pen, x.cikmis, x.kasa, x.temiz, x.aday, x.v29, x.durum, x.oncelik, '']);
    if (x.durum === 'YENİ BASIM') rr.getCell(9).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF8CBAD' } }; if (x.durum === 'KALIBA ADAY VAR') rr.getCell(9).fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFC6EFCE' } }; }
  wk.columns.forEach((c, i) => { c.width = [26, 44, 14, 12, 14, 12, 16, 10, 28, 9, 22][i] || 12; }); wk.views = [{ state: 'frozen', ySplit: 3 }]; wk.autoFilter = { from: { row: 3, column: 1 }, to: { row: 3 + tekil.length + 20, column: 11 } };
  const out = path.join(kok, 'sql-yerel', `SINAV-SGS-${tarih}-HUNI.xlsx`); await wb.xlsx.writeFile(out);
  console.log('yazildi: ' + out);
  console.log(['Ders', 'Sınav', 'PencereKonu', 'AdayVar', 'Boş', 'EskiAday', 'v29', 'Hedef5'].join('\t'));
  for (const d of derslerSira) { const o = ozet.get(d); console.log([d, SINAV_SORU[d], o.pencereKonu, o.adayVar, o.bos, o.eskiAday, o.v29, SINAV_SORU[d] * 5].join('\t')); }
  console.log(['TOPLAM', T.s, T.p, T.a, T.b, T.e, T.v, T.h].join('\t'));
})().catch(e => { console.error('HATA: ' + e.message); process.exit(1); });
