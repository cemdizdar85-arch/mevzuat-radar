#!/usr/bin/env node
// ============================================================================
//  KAPI-ADIM — ADIM ATFI KAYMASI KAPISI + MEKANİK ONARIM (30.09.2026, SMMM oturumu ölçtü, SGS'de de ölçüldü)
//  Çözüm adımlarında "<sayı> (N. adımda bulduk)" notu, sitede "adım N" diye gösterilir; site adimlar[j]'yi "Adım j+1" diye numaralar
//  (kaydir/*.html: title="Adım '+(j+1)+'"; ilk "Verilen" satırı Adım 1). Doğru atıf: değer adimlar[N-1].formul içinde "= <sayı>" sonucu.
//    ADIM-KAYMA : değer adimlar[N-1]'de sonuç değil, ÖNCEKİ başka bir adımda sonuç (DURDURUR; onar() tek adayda numarayı düzeltir)
//    ADIM-YOK   : değer hiçbir önceki adımda "= <sayı>" olarak yok (yalnız NOT — biçim farkı olabilir: "= 150.000 TL", yuvarlama)
//  ÖLÇÜLDÜ (30.09): SMMM bitirme 2.399 soruda 9.409 atıf, 2.424 yanlış (kaymanın 2.072'si +1). SGS sitesi 5.216 atıf, 1.492 yanlış (561 soru):
//    +1 1.050 · +2 121 · −1 30 · yok 291. Kök: üretimde adimlar[0] "Verilen" satırı sayılmadan numara verilmiş.
//  🚫 GÖRMEZ: "adımda bulduk" dışındaki atıf biçimleri ("yukarıda bulduğumuz", "Adım 3'teki") · anlatim alanı · aynı değer iki adımda
//     sonuçsa (belirsiz → onarılmaz) · sonucu "=" ile değil "→" ile yazılmış adım.
//  Kullanım: node arac/adim-atif-kapisi.js --sinav [--mutasyon] | --banka <sgs|smmm|kgk> [cikti.json] | --taslak <sgs|smmm> <klasör>
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const MUT = process.env.ADIM_MUTASYON || '';
const ATIF = /([\d.]+(?:,\d+)?)(\s*(?:₺|TL|gün|adet|birim|%)?\s*\()(\d{1,2})(\.\s*ad[ıi]mda)/g;
const esc = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

function incele(k) {
  const out = []; if (!k || !Array.isArray(k.adimlar)) return out;
  const A = k.adimlar;
  // "= <sayı>" SONUÇ olmalı: ardından "(soruda verilen)" / "(N. adımda bulduk)" gibi bir not geliyorsa o, değerin KULLANIMIDIR, sonucu değil
  const sonuc = (j, deger) => j >= 0 && A[j] && new RegExp('=\\s*' + esc(deger) + '(?![\\d,])(?!\\s*(?:₺|TL|gün|adet|birim|%)?\\s*\\()').test(String(A[j].formul || ''));
  A.forEach((a, i) => {
    const f = String((a && a.formul) || '');
    for (const z of f.matchAll(ATIF)) {
      const deger = z[1], N = +z[3];
      if (MUT !== 'hep-dogru' && sonuc(N - 1, deger)) continue;
      if (MUT === 'hep-dogru') continue;
      const adaylar = []; for (let j = 0; j < i; j++) if (sonuc(j, deger)) adaylar.push(j);
      if (!adaylar.length && MUT !== 'yok-kapali') { out.push({ tur: 'ADIM-YOK', alan: 'adimlar[' + i + '].formul', N, deger }); continue; }
      out.push({ tur: 'ADIM-KAYMA', alan: 'adimlar[' + i + '].formul', N, deger, dogruN: adaylar.length === 1 ? adaylar[0] + 1 : null });
    }
  });
  return out;
}
function kusurlar(k) { return incele(k); }

// Mekanik onarım: yalnız tek adaylı kaymalar. Döner: {yeni, degisen:[yol]} ya da null
function onar(k) {
  const b = incele(k).filter(x => x.tur === 'ADIM-KAYMA' && x.dogruN); if (!b.length) return null;
  const yeni = JSON.parse(JSON.stringify(k)); const degisen = new Set();
  const byI = {}; for (const x of b) { const i = +x.alan.match(/\[(\d+)\]/)[1]; (byI[i] = byI[i] || []).push(x); }
  for (const [i, L] of Object.entries(byI)) {
    let f = String(yeni.adimlar[i].formul);
    f = f.replace(ATIF, (tam, deger, ara, N, son) => { const h = L.find(x => x.deger === deger && x.N === +N); return h ? deger + ara + h.dogruN + son : tam; });
    if (f !== yeni.adimlar[i].formul) { yeni.adimlar[i].formul = f; degisen.add('adimlar[' + i + '].formul'); }
  }
  return degisen.size ? { yeni, degisen: [...degisen] } : null;
}

function yayinIds(sinav) {
  const d = path.join(KOK, 'veri', 'sinav', 'kaydir-secim'); const ids = new Set();
  for (const f of fs.readdirSync(d).filter(f => new RegExp('^(yayin|vitrin)-' + sinav + '-').test(f))) for (const r of JSON.parse(fs.readFileSync(path.join(d, f), 'utf8').replace(/^﻿/, ''))) if (r.etiket && r.id) ids.add(r.etiket + '/' + r.id);
  return ids;
}
function kayitlar(sinav, fn) {
  const P = {}; let okunan = 0;
  for (const id of yayinIds(sinav)) {
    const [e, kp] = id.split('/'); const pf = path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + e + '.json');
    if (!(e in P)) P[e] = fs.existsSync(pf) ? JSON.parse(fs.readFileSync(pf, 'utf8').replace(/^﻿/, '')) : null;
    const k = P[e] && P[e][kp]; if (!k) continue; okunan++; fn(id, e, kp, k);
  }
  return okunan;
}
function banka(sinav, cikti) {
  const sonuc = []; const tur = {}; let onarilabilir = 0;
  const okunan = kayitlar(sinav, (id, e, kp, k) => { const b = incele(k); if (b.length) { sonuc.push({ anahtar: id, kusurlar: b }); for (const x of b) tur[x.tur] = (tur[x.tur] || 0) + 1; if (onar(k)) onarilabilir++; } });
  console.log(`KAPI-ADIM banka (${sinav}): okunan ${okunan} · bulgulu soru ${sonuc.length} · ${JSON.stringify(tur)} · mekanik onarılabilir soru ${onarilabilir}`);
  if (cikti) fs.writeFileSync(cikti, JSON.stringify(sonuc, null, 1));
}
function taslak(sinav, klasor) {
  const ret = JSON.parse(fs.readFileSync(path.join(KOK, 'veri', 'sinav', sinav + '-elle-ret.json'), 'utf8').replace(/^﻿/, '')).kayitlar || {};
  fs.mkdirSync(path.join(klasor, '_tam'), { recursive: true }); let n = 0, kalan = 0;
  kayitlar(sinav, (id, e, kp, k) => {
    if (ret[id]) return; const r = onar(k); if (!r) return;
    const eski = {}, yeni = {}; for (const y of r.degisen) { const i = +y.match(/\[(\d+)\]/)[1]; eski[y] = k.adimlar[i].formul; yeni[y] = r.yeni.adimlar[i].formul; }
    fs.writeFileSync(path.join(klasor, e + '__' + kp + '.json'), JSON.stringify({ etiket: e, kp, karar: 'ADIM ATFI KAYMASI', dogru_eski: k.dogru, dogru_yeni: k.dogru, kok_degisti: false,
      degisen_alanlar: r.degisen, eski, yeni, gerekce: '"(N. adımda bulduk)" notu değerin sonuç olarak bulunduğu adımı göstermiyordu; site adimlar[j]\'yi "Adım j+1" diye numaralar. Mekanik düzeltme (arac/adim-atif-kapisi.js), yalnız tek adaylı kaymalar.', dayanak: 'kaydir/*.html adım numaralama' }, null, 1));
    fs.writeFileSync(path.join(klasor, '_tam', e + '__' + kp + '.tam.json'), JSON.stringify(r.yeni, null, 1));
    n++; if (incele(r.yeni).some(x => x.tur === 'ADIM-KAYMA')) kalan++;
  });
  console.log('KAPI-ADIM taslak (' + sinav + '): ' + n + ' soru · onarım sonrası hâlâ KAYMA taşıyan ' + kalan + ' (çok adaylı / ayrı atıf)');
}

function sinav() {
  const T = () => ({ dogru: 'A', adimlar: [
    { formul: 'Verilen: satış 1.000, maliyet 600' },
    { formul: 'Brüt kâr = 1.000 − 600 = 400' },
    { formul: 'Vergi = 400 (2. adımda bulduk) × %25 = 100' },
    { formul: 'Net = 400 (2. adımda bulduk) − 100 (3. adımda bulduk) = 300' }] });
  const V = [
    ['doğru atıflar → temiz', T(), 0, null],
    ['+1 kayma → KAYMA, onarılır', (() => { const k = T(); k.adimlar[2].formul = 'Vergi = 400 (1. adımda bulduk) × %25 = 100'; return k; })(), 1, 'Vergi = 400 (2. adımda bulduk) × %25 = 100'],
    ['değer hiçbir adımda yok → ADIM-YOK (not)', (() => { const k = T(); k.adimlar[3].formul = 'Net = 999 (2. adımda bulduk) − 100 (3. adımda bulduk) = 300'; return k; })(), 'ADIM-YOK', null],
    ['aynı değer iki önceki adımda sonuç → belirsiz, onarılmaz', (() => { const k = T(); k.adimlar[0].formul = 'Verilen: kâr = 400'; k.adimlar[2].formul = 'Vergi = 400 (3. adımda bulduk) × %25 = 100'; return k; })(), 1, null],
    ['sonraki adıma işaret eden (değer ancak ileride sonuç) → aday yok, onarılmaz', (() => { const k = T(); k.adimlar[1].formul = 'Brüt kâr = 1.000 − 600 = 400; bkz. 100 (2. adımda bulduk)'; return k; })(), 1, null],
    ['kullanım "= 400 (2. adımda bulduk)" sonuç sayılmaz', (() => { const k = T(); k.adimlar[3].formul = 'Net = 400 (3. adımda bulduk) − 100 (3. adımda bulduk) = 300'; return k; })(), 1, 'Net = 400 (2. adımda bulduk) − 100 (3. adımda bulduk) = 300'],
    ['"TL" birimli atıf da okunur', (() => { const k = T(); k.adimlar[2].formul = 'Vergi = 400 TL (1. adımda bulduk) × %25 = 100'; return k; })(), 1, 'Vergi = 400 TL (2. adımda bulduk) × %25 = 100'],
  ];
  let ok = 0;
  for (const [ad, k, bek, onarSonra] of V) {
    const b = incele(k); let t = typeof bek === 'string' ? (b.length === 1 && b[0].tur === bek) : b.length === bek;
    if (t && onarSonra !== undefined) { const r = onar(k); t = onarSonra === null ? !r || !b.some(x => x.dogruN) : !!r && r.yeni.adimlar.some(a => a.formul === onarSonra) && incele(r.yeni).length === 0; }
    if (t) ok++; console.log((t ? '  ✓ ' : '  ✗ ') + ad + (t ? '' : ' → ' + JSON.stringify(b)));
  }
  console.log((ok === V.length ? 'KAPI-ADIM ÖZ-SINAVI YEŞİL' : 'KAPI-ADIM ÖZ-SINAVI KIRMIZI') + ` (${ok}/${V.length})` + (MUT ? ' · ADIM_MUTASYON=' + MUT : ''));
  return ok === V.length;
}

module.exports = { kusurlar, onar };
if (require.main === module) {
  const [a, b, c] = process.argv.slice(2);
  if (a === '--sinav') {
    if (process.argv.includes('--mutasyon')) {
      const { spawnSync } = require('child_process'); const ler = ['hep-dogru', 'yok-kapali']; let tutan = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, ADIM_MUTASYON: m }, encoding: 'utf8' }); const kr = r.status !== 0; if (kr) tutan++; console.log('  mutasyon ' + m + (kr ? ' KIRMIZI (doğru)' : ' YEŞİL (SINAV KÖR!)')); }
      console.log('MUTASYON: ' + tutan + '/' + ler.length + ' → KIRMIZI'); process.exit(tutan === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  } else if (a === '--banka') banka(b || 'sgs', c);
  else if (a === '--taslak') taslak(b || 'sgs', c);
  else if (a === '--duzelt-parti') {   // üretim içi kullanım için: bir parti dosyasındaki tek adaylı kaymaları yerinde düzeltir (--yaz olmadan kuru)
    const pf = b, yaz = process.argv.includes('--yaz'); const h = fs.readFileSync(pf, 'utf8'); const bom = h.charCodeAt(0) === 0xfeff; const P = JSON.parse(h.replace(/^﻿/, ''));
    let n = 0, yol = 0; for (const kp of Object.keys(P)) { if (!/^kp-/.test(kp)) continue; const r = onar(P[kp]); if (r) { P[kp] = r.yeni; n++; yol += r.degisen.length; } }
    if (yaz && n) fs.writeFileSync(pf, (bom ? '﻿' : '') + JSON.stringify(P, null, 4));
    console.log('KAPI-ADIM düzelt (' + path.basename(pf) + '): ' + n + ' soru · ' + yol + ' formül' + (yaz ? ' YAZILDI' : ' (kuru)'));
  }
  else { console.log('--sinav [--mutasyon] | --banka <sgs|smmm|kgk> [cikti.json] | --taslak <sgs|smmm> <klasör>'); process.exit(2); }
}
