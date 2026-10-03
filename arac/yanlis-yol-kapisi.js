#!/usr/bin/env node
// ============================================================================
//  KAPI-YY — YANLIŞ YOL ŞIKKA VARIYOR MU KAPISI (03.10.2026) · 0 USD · YALNIZ NOT
//  Çözüm adımlarında "Yanlış yol:" / "En sık hata" ile başlayan adım bilerek yapılan hatayı gösterir; bu hatalı hesabın
//  SONUCU bir çeldiricinin (doğru olmayan şık) değerine varmalı. 03.10 elle okumada ~20 soruda varmıyordu
//  ("294.000 / 2 = 147.000" ama şık 147.500; "= 12.852" hiçbir şık değil).
//    TAMAM     : yanlış yolun sonucu bir YANLIŞ şıkkın sayısal değerine eşit
//    YY-DOGRU  : sonuç DOĞRU şıkka eşit (hata yolu doğru cevaba çıkıyor — ciddi)
//    YY-SIKSIZ : sonuç hiçbir şıkka eşit değil
//    ölçülmedi : SOZEL (sayısal şık < 4) · YY-YOK (yanlış-yol adımı yok) · SONUC-YOK (adımda "= <sayı>" sonucu yok)
//  Sonuç = adımın "(HATALI)" ya da "→ doğrusu" öncesindeki kısmında SON "=" işaretinin ardındaki sayı (o "=" sayıyla
//  bitmiyorsa SONUC-YOK). Eşitlik: iki sayı az ondalıklı olanın hanesine yuvarlanınca aynı (433.333 = 433.333,33; 147.000 ≠ 147.500).
//  ÖLÇÜLDÜ (03.10 --kasa): SGS taranan 4.951 · sayısal 1.648 · YY adımlı 974 → TAMAM 667 · YY-SIKSIZ 244 · YY-DOGRU 13.
//    SMMM taranan 3.820 · sayısal 1.995 · YY adımlı 1.961 → TAMAM 1.288 · YY-SIKSIZ 553 · YY-DOGRU 12.
//    Elle okunan 15 bulgunun 13'ü gerçek, 2'si yanlış alarmdı ("500.000'den büyük" sözel; 0,06 ≈ 0,064/0,060) — ikisi düzeltildi,
//    öz-sınava vaka oldu. Düzeltme sonrası 25 YY-DOGRU elle tarandı: 1'i sınırda ("x = -7 veya x = 5 ikisini yazmak", sözel hata).
//  DÜZEY: yalnız NOT — soru durdurmaz, üretime/yayına BAĞLI DEĞİL. Yanlış alarm oranı ölçülmeden durdurucu yapılmaz.
//  🚫 GÖRMEZ: sözel yanlış yol ("stok kaydı yapılmaz denir") · şıkkı çoklu sayı / sayı+yön sözcüğü olan sorular
//     ("12.000 olumsuz", "Borç 3.500 / Alacak 3.500", tarih) · yanlış yolun MANTIĞININ doğru olup olmadığı (yalnız sonucun
//     şıkka varıp varmadığı) · son "=" ara sonuçsa ("= 0,60" ama şık "%60" gibi ölçek farkı) · "Yanlış yol"/"En sık hata"
//     dışında başlayan hata adımları ("Tuzak:", "Dikkat:") · sonucu "=" değil "→" ile yazılmış adım · anlatim/aciklama alanları.
//  Kullanım: node arac/yanlis-yol-kapisi.js --sinav [--mutasyon] | --kasa <sgs|smmm> [cikti.json]
// ============================================================================
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const MUT = process.env.YY_MUTASYON || '';
const ESIK = MUT === 'esik-3' ? 3 : MUT === 'esik-6' ? 6 : 4;          // sayısal şık eşiği
const YY_BAS = /^[\s*_"'“”(•\-–—]*(yanlış\s+yol|en\s+sık\s+hata)/i;
const KES = /\(\s*HATALI|(?:→|->|⇒)\s*doğru/i;
const BIRIM = /^(?:tl|₺|%|gün|ay|yıl|adet|birim|saat|dakika|hafta|kişi|kg|ton|km|m²|m2|m³|lt|litre|metre|cm|puan|kat|tl\/(?:kg|birim|saat|adet|ay)|₺\/(?:kg|birim|saat|adet|ay))$/i;
const SAYI = /^[−-]?\d+(?:[.,]\d+)*$/;

// Türkçe sayı: 1.234.567,89 → {v, d}. Tek nokta + 3 hane değilse ondalık sayılır (0.5, 1.3492).
function sayiCoz(s) {
  s = String(s).trim().replace(/−/g, '-').replace(/\.+$/, '');
  if (!SAYI.test(s)) return null;
  let t;
  if (s.includes(',')) { if ((s.match(/,/g) || []).length > 1) return null; t = s.replace(/\./g, '').replace(',', '.'); }
  else if (/^-?\d{1,3}(\.\d{3})+$/.test(s)) t = s.replace(/\./g, '');
  else if ((s.match(/\./g) || []).length === 1) t = s;
  else if (!s.includes('.')) t = s; else return null;
  const v = Number(t); if (!isFinite(v)) return null;
  const d = t.includes('.') ? t.split('.')[1].length : 0;
  return { v, d };
}
// Şık metni tek bir sayıysa (birim/₺/TL/% temizlenince) değeri; değilse null
function sikSayi(m) {
  let s = String(m == null ? '' : m).trim();
  if (MUT !== 'birim-yok') {
    s = s.replace(/^₺\s*/, '').replace(/^%\s*/, '');
    const p = s.split(/\s+/); while (p.length > 1 && BIRIM.test(p[p.length - 1])) p.pop(); s = p.join(' ');
    s = s.replace(/\s*(₺|%|TL)$/i, '');
  }
  return sayiCoz(s);
}
function esit(a, b) {
  if (MUT === 'tolerans-sifir') return a.v === b.v;
  if (MUT === 'tolerans-gevsek') return Math.abs(a.v - b.v) <= 0.01 * Math.max(Math.abs(a.v), Math.abs(b.v));
  const p = Math.min(a.d, b.d), k = Math.pow(10, p);
  return Math.round(a.v * k + 1e-9 * Math.sign(a.v)) === Math.round(b.v * k + 1e-9 * Math.sign(b.v));
}
// Yanlış-yol adımının sonuç sayısı (yoksa null)
function yySonuc(f) {
  f = String(f || '');
  let on = f; if (MUT !== 'kesme-yok') { const m = f.search(KES); if (m >= 0) on = f.slice(0, m); }
  const es = [...on.matchAll(/[=≈]/g)]; if (!es.length) return null;
  const sec = MUT === 'ilk-esit' ? es[0] : es[es.length - 1];
  const kuyruk = on.slice(sec.index + 1);
  // 03.10 kasa okuması: "= 500.000'den büyük bir tutar" sözel — sayıya bitişik ek ('den, 'e…) sonuç sayılmaz
  const z = kuyruk.match(/^\s*(?:₺\s*|%\s*)?([−-]?\s?\d[\d.,]*\d|\d)(?![.,]?\d)(?![/^a-zçğıöşüA-ZÇĞİÖŞÜ])(?!['’]\s*[a-zçğıöşü])\s*(✓|✔)?/);
  if (MUT === 'ek-kabul' && !z) { const z2 = kuyruk.match(/^\s*(?:₺\s*|%\s*)?([−-]?\s?\d[\d.,]*\d|\d)['’]/); if (z2) return sayiCoz(z2[1].replace(/\s/g, '')); }
  if (!z || z[2]) return null;                                        // "= 160.800 ₺ ✓" sağlama sonucu yanlış yol değildir
  return sayiCoz(z[1].replace(/\s/g, '').replace(/,$/, ''));
}
const AGIRLIK = { 'YY-DOGRU': 3, 'YY-SIKSIZ': 2, 'TAMAM': 1 };
// Döner: { sinif, adimlar:[{i, sonuc, sinif, esit_harf}], sayisal_sik }
function incele(k) {
  const r = { sinif: null, adimlar: [], sayisal_sik: 0 };
  if (!k || typeof k !== 'object' || !k.siklar || typeof k.siklar !== 'object') { r.sinif = 'SOZEL'; return r; }
  const S = {}; for (const [h, m] of Object.entries(k.siklar)) { if (!/^[A-E]$/.test(h)) continue; const n = sikSayi(m); if (n) S[h] = n; }
  r.sayisal_sik = Object.keys(S).length;
  if (r.sayisal_sik < ESIK) { r.sinif = 'SOZEL'; return r; }
  const A = Array.isArray(k.adimlar) ? k.adimlar : [];
  let yyVar = false;
  A.forEach((a, i) => {
    const f = String((a && a.formul) || '');
    if (MUT !== 'her-adim' && !YY_BAS.test(f)) return;
    yyVar = true;
    const n = yySonuc(f); if (!n) return;
    // 03.10 kasa okuması: "= 0,06" hem 0,064 (doğru) hem 0,060 (çeldirici) ile yuvarlamada eşit → EN YAKIN şık alınır, eşitlikte çeldirici
    const adaylar = Object.keys(S).filter(h => esit(n, S[h]));
    const harf = MUT === 'en-yakin-yok' ? adaylar[0] : adaylar.sort((x, y) => (Math.abs(S[x].v - n.v) - Math.abs(S[y].v - n.v)) || ((x === k.dogru) - (y === k.dogru)))[0];
    let s = !harf ? 'YY-SIKSIZ' : harf === k.dogru ? 'YY-DOGRU' : 'TAMAM';
    if (s === 'YY-SIKSIZ' && MUT === 'yakalama-siksiz') s = 'TAMAM';
    if (s === 'YY-DOGRU' && MUT === 'yakalama-dogru') s = 'TAMAM';
    r.adimlar.push({ i, sonuc: n.v, sinif: s, esit_harf: harf || null });
  });
  if (!yyVar) r.sinif = 'YY-YOK';
  else if (!r.adimlar.length) r.sinif = 'SONUC-YOK';
  else r.sinif = r.adimlar.reduce((m, x) => AGIRLIK[x.sinif] > AGIRLIK[m] ? x.sinif : m, 'TAMAM');
  return r;
}
function kusurlar(k) { const r = incele(k); return r.adimlar.filter(x => x.sinif !== 'TAMAM').map(x => ({ tur: x.sinif, alan: 'adimlar[' + x.i + '].formul', sonuc: x.sonuc })); }

// --kasa: kimlikler kasadan (paket_soru), içerik yerel partiden — adim-atif-kapisi.js ile AYNI düzen.
async function kasaIds(sinav) {
  const KEY = String(process.env.SUPABASE_SERVICE_KEY || '').trim(); if (!KEY) { console.log('SUPABASE_SERVICE_KEY yok — kasa okunamaz'); process.exit(2); }
  const ids = [];
  for (let ofs = 0; ; ofs += 1000) {
    const r = await fetch(`https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id&sinav=eq.${sinav}&order=id.asc&limit=1000&offset=${ofs}`,
      { headers: { apikey: KEY, Authorization: 'Bearer ' + KEY, 'User-Agent': 'mevzuat-radar-robot/1.0' } });
    if (!r.ok) { console.log('kasa okunamadı: HTTP ' + r.status); process.exit(2); }
    const d = await r.json(); for (const x of d) if (x.id) ids.push(String(x.id)); if (d.length < 1000) break;
  }
  if (!ids.length) { console.log('kasada ' + sinav + ' sorusu 0 — durdu'); process.exit(2); }
  return ids;
}
async function kasa(sinav, cikti) {
  const ids = await kasaIds(sinav);
  const retY = path.join(KOK, 'veri', 'sinav', sinav + '-elle-ret.json');
  const ret = fs.existsSync(retY) ? (JSON.parse(fs.readFileSync(retY, 'utf8').replace(/^﻿/, '')).kayitlar || {}) : {};
  const P = {}; let okunan = 0, kor = 0, rette = 0; const sinif = {}; const sonuc = [];
  for (const id of ids) {
    if (ret[id]) { rette++; continue; }
    const [e, kp] = id.split('/'); const pf = path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + e + '.json');
    if (!(e in P)) P[e] = fs.existsSync(pf) ? JSON.parse(fs.readFileSync(pf, 'utf8').replace(/^﻿/, '')) : null;
    const k = P[e] && P[e][kp]; if (!k) { kor++; continue; } okunan++;
    const r = incele(k); sinif[r.sinif] = (sinif[r.sinif] || 0) + 1;
    // çıktıda soru metni YOK (depo public): yalnız kimlik + sınıf + sayılar
    sonuc.push({ anahtar: id, sinif: r.sinif, dogru: k.dogru || null, sayisal_sik: r.sayisal_sik, adimlar: r.adimlar });
  }
  const c = x => sinif[x] || 0;
  const sayisal = okunan - c('SOZEL'), yyli = sayisal - c('YY-YOK');
  const olculmedi = c('SOZEL') + c('YY-YOK') + c('SONUC-YOK');
  console.log(`KAPI-YY kasa (${sinav}): kasada ${ids.length} · elle rette ${rette} · KÖR (yerel partide yok) ${kor} · taranan ${okunan} · sayısal ${sayisal} · yanlış-yol adımı olan ${yyli}`);
  console.log(`  TAMAM ${c('TAMAM')} · YY-SIKSIZ ${c('YY-SIKSIZ')} · YY-DOGRU ${c('YY-DOGRU')} · ölçülmedi ${olculmedi} (sözel ${c('SOZEL')} · yanlış-yol yok ${c('YY-YOK')} · sonuç sayısı yok ${c('SONUC-YOK')})`);
  if (cikti) fs.writeFileSync(cikti, JSON.stringify({ sinav, tarih: new Date().toISOString(), sayim: { kasada: ids.length, rette, kor, taranan: okunan, sayisal, yanlis_yollu: yyli, ...sinif }, sorular: sonuc.filter(x => x.sinif === 'YY-SIKSIZ' || x.sinif === 'YY-DOGRU' || x.sinif === 'TAMAM') }, null, 1));
}

function sinav() {
  const SIK = () => ({ A: '120.000', B: '147.500', C: '150.000', D: '160.000', E: '175.000' });
  const T = (yy, ek) => Object.assign({ dogru: 'C', siklar: SIK(), adimlar: [
    { formul: 'Verilen: maliyet 300.000, pay 1/2' },
    { formul: 'Pay = 300.000 / 2 = 150.000' },
    ...(yy == null ? [] : [{ formul: yy }])] }, ek || {});
  const V = [
    ['yanlış yol çeldiriciye varıyor → TAMAM', T('Yanlış yol: 300.000 / 2 − 2.500 = 147.500 (HATALI) → doğrusu 150.000 (2. adımda bulduk)'), 'TAMAM'],
    ['"294.000 / 2 = 147.000" şık 147.500 → YY-SIKSIZ', T('Yanlış yol: 294.000 / 2 = 147.000 (HATALI) → doğrusu 150.000 (2. adımda bulduk)'), 'YY-SIKSIZ'],
    ['"= 12.852" hiçbir şık değil → YY-SIKSIZ', T('Yanlış yol: 300.000 × %4,284 = 12.852 (HATALI) → doğrusu 150.000'), 'YY-SIKSIZ'],
    ['yanlış yol DOĞRU şıkka çıkıyor → YY-DOGRU', T('Yanlış yol: 100.000 + 50.000 = 150.000 (HATALI) → doğrusu 150.000 (2. adımda bulduk)'), 'YY-DOGRU'],
    ['"En sık hata = … = 147.000 (brüt alındı)" HATALI yok → YY-SIKSIZ', T('En sık hata = 294.000 / 2 = 147.000 (brüt alındı)'), 'YY-SIKSIZ'],
    ['sözel şıklı soru → ölçülmedi (SOZEL)', T('Yanlış yol: 294.000 / 2 = 147.000 (HATALI) → doğrusu 150.000',
      { siklar: { A: 'Gider yazılır', B: 'Aktifleştirilir', C: 'Karşılık ayrılır', D: 'Hiç kaydedilmez', E: 'Özkaynağa alınır' } }), 'SOZEL'],
    ['3 sayısal + 2 sözel şık → ölçülmedi (eşik 4)', T('Yanlış yol: 294.000 / 2 = 147.000 (HATALI) → doğrusu 150.000',
      { siklar: { A: '120.000', B: '147.500', C: '150.000', D: 'Hesaplanamaz', E: 'Karşılık ayrılmaz' } }), 'SOZEL'],
    ['₺/TL ve ",00" biçim farkı → TAMAM', T('Yanlış yol: 300.000 / 2 − 2.500 = 147.500,00 TL (HATALI) → doğrusu 150.000 ₺',
      { siklar: { A: '120.000 ₺', B: '147.500 ₺', C: '150.000 ₺', D: '160.000 TL', E: '₺175.000' } }), 'TAMAM'],
    ['ondalık yuvarlama 433.333 ≈ 433.333,33 → TAMAM', T('Yanlış yol: 5.200.000 / 12 = 433.333 (HATALI) → doğrusu 360.000',
      { dogru: 'A', siklar: { A: '360.000', B: '433.333,33', C: '400.000', D: '520.000', E: '300.000' } }), 'TAMAM'],
    ['sağlama satırı "= 150.000 ₺ ✓" yanlış yol sayılmaz → TAMAM', (() => { const k = T('Yanlış yol: 300.000 / 2 − 2.500 = 147.500 (HATALI) → doğrusu 150.000');
      k.adimlar.push({ formul: 'Sağlama: 120.000 + 30.000 = 150.000 ₺ ✓' }); return k; })(), 'TAMAM'],
    ['aynı adımda çok "=" → SONUNCU alınır → TAMAM', T('Yanlış yol: 300.000 / 2 = 150.000; 150.000 − 2.500 = 147.500 (HATALI) → doğrusu 150.000'), 'TAMAM'],
    ['"→ doğrusu … = 150.000" kesilir, öncesi alınır → TAMAM', T('Yanlış yol: toplam = 147.500 (HATALI) → doğrusu 147.500 + 2.500 = 150.000 (2. adımda bulduk)'), 'TAMAM'],
    ['yanlış-yol adımı yok → ölçülmedi (YY-YOK)', T(null), 'YY-YOK'],
    ['sözel yanlış yol → ölçülmedi (SONUC-YOK)', T('Yanlış yol: stok kaydı yapılmaz denir (HATALI) → doğrusu 150.000 (2. adımda bulduk)'), 'SONUC-YOK'],
    ['yüzde şık "%25" ve eksi "−12.000" → TAMAM', T('Yanlış yol: 30.000 − 42.000 = −12.000 (HATALI) → doğrusu %25',
      { dogru: 'B', siklar: { A: '-12.000', B: '%25', C: '%30', D: '%35', E: '%40' } }), 'TAMAM'],
    // 03.10 --kasa elle okumasında çıkan iki yanlış alarm (sgs-c2-ekonomi-kolay-r2/kp-01, smmm-4k-a-yfta-zor-r7/kp-10)
    ['"= 150.000\'den büyük bir tutar" sözel → ölçülmedi (SONUC-YOK)', T('Yanlış yol: dışlamayı da eklemek = 150.000\'den büyük bir tutar (HATALI) → doğrusu 150.000'), 'SONUC-YOK'],
    ['"= 0,06" hem 0,064 (doğru) hem 0,060 ile eşit → en yakın çeldirici → TAMAM', T('Yanlış yol: 240.000 / 4.000.000 = 0,06 (HATALI) → doğrusu 0,064',
      { dogru: 'A', siklar: { A: '0,064', B: '0,060', C: '0,080', D: '0,120', E: '0,300' } }), 'TAMAM'],
  ];
  let ok = 0;
  for (const [ad, k, bek] of V) { const r = incele(k); const t = r.sinif === bek; if (t) ok++; console.log((t ? '  ✓ ' : '  ✗ ') + ad + (t ? '' : ' → ' + r.sinif + ' ' + JSON.stringify(r.adimlar))); }
  console.log((ok === V.length ? 'KAPI-YY ÖZ-SINAVI YEŞİL' : 'KAPI-YY ÖZ-SINAVI KIRMIZI') + ` (${ok}/${V.length})` + (MUT ? ' · YY_MUTASYON=' + MUT : ''));
  return ok === V.length;
}

module.exports = { kusurlar, incele };
if (require.main === module) {
  const [a, b, c] = process.argv.slice(2);
  if (a === '--sinav') {
    if (process.argv.includes('--mutasyon')) {
      if (!sinav()) { console.log('MUTASYON koşulmadı: bozulmamış öz-sınav zaten KIRMIZI'); process.exit(1); }
      const { spawnSync } = require('child_process');
      const ler = ['yakalama-siksiz', 'yakalama-dogru', 'tolerans-sifir', 'tolerans-gevsek', 'esik-3', 'esik-6', 'ilk-esit', 'kesme-yok', 'her-adim', 'birim-yok', 'ek-kabul', 'en-yakin-yok'];
      let tutan = 0;
      for (const m of ler) { const r = spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, YY_MUTASYON: m }, encoding: 'utf8' }); const kr = r.status !== 0; if (kr) tutan++; console.log('  mutasyon ' + m + (kr ? ' KIRMIZI (doğru)' : ' YEŞİL (SINAV KÖR!)')); }
      console.log('MUTASYON: ' + tutan + '/' + ler.length + ' mutasyon KIRMIZI'); process.exit(tutan === ler.length ? 0 : 1);
    }
    process.exit(sinav() ? 0 : 1);
  } else if (a === '--kasa') kasa(b || 'sgs', c).catch(e => { console.log('kasa hatası: ' + e.message); process.exit(2); });
  else { console.log('--sinav [--mutasyon] | --kasa <sgs|smmm> [cikti.json]'); process.exit(2); }
}
