#!/usr/bin/env node
// ============================================================================
//  SGS YAYIN RİSK TARAMASI (29.09.2026, Cem "1.2.3" — açılış öncesi, 0 USD)
//  Yayındaki SGS sorularını (kaydir-secim/yayin-sgs-*.json + vitrin) yerel parti kayıtlarından okur ve
//  "elle okunmalı" risk sınıflarına ayırır. HİÇBİR ŞEY YAZMAZ/ÇEKMEZ — yalnız liste üretir:
//    veri/sinav/sgs-risk-taramasi.json  (+ özet stdout)
//  SINIFLAR (bir soru birden çok sınıfta olabilir):
//    R1 YIL-BAĞLI TUTAR/ORAN  — asgari ücret, had/sınır/tavan/taban, gecikme zammı/faiz oranı, amortisman oranı,
//                               vergi/SGK oranı + tutar, "20xx yılı" + tutar
//    R2 MÜLGA KAYNAK          — kaynak_adlar veri/sinav/ambar-mulga-maddeler.json'daki maddede (KAPI-MM)
//    R3 DEĞİŞEN MADDE, ÇEKİLMEMİŞ — nöbetçinin "değmeyen" listesi (paketinde değişen madde vardı, soru belirtece değmedi)
//    R4 HESAPLI               — şıkların en az 4'ü sayı
//    R5 KAYITSIZ              — yayında ama yerel partide kayıt yok (okunamadı = KÖR)
//  🚫 GÖRMEZ: anlam/mantık hatası (hesapsız, yıl-bağsız sözel soru) · ambarla yerel parti farkı (önce parti-senkron -Indir)
//     · kasa modundaki sayfanın seçimden sonra düşen sorusu. Bu sınıflar "taranmadı" sayılır, "temiz" değil.
//  Kullanım: node arac/sgs-risk-tarama.js [--sinav]
// ============================================================================
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const oku = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, ''));

const R1_RX = [
  [/asgari\s+ücret/i, 'asgari ücret'],
  [/\b(had(di|ler)?|sınır(ı|lar)?|tavan(ı)?|taban(ı)?)\b[^.]{0,60}\d{1,3}(\.\d{3})+/i, 'had/sınır/tavan + tutar'],
  [/\d{1,3}(\.\d{3})+[^.]{0,60}\b(had(di)?|sınır(ı)?|tavan(ı)?|taban(ı)?)\b/i, 'tutar + had/sınır'],
  [/gecikme\s+(zammı|faizi)|tecil\s+faizi|reeskont\s+faiz|yasal\s+faiz/i, 'gecikme/tecil/reeskont faizi'],
  [/amortisman\s+oran/i, 'amortisman oranı'],
  [/(prime\s+esas\s+kazanç|pek)\b[^.]{0,40}(alt|üst)\s+sınır/i, 'SGK PEK sınırı'],
  [/\b(20[0-3]\d)\s+yılı(nda|na|nın)?\b[^.]{0,80}\d{1,3}(\.\d{3})+/i, 'yıl + tutar'],
  [/(vergi|stopaj|tevkifat|kdv|ötv|damga|harç)[^.]{0,30}%\s?\d|%\s?\d+[^.]{0,30}(vergi|stopaj|tevkifat|kdv|ötv|damga)/i, 'vergi oranı'],
  [/değerli\s+konut|emlak\s+vergisi\s+değer|yeniden\s+değerleme\s+oran/i, 'yıllık ilan edilen değer/oran'],
];
function metin(q) {
  const s = [q.soru, ...(q.siklar ? Object.values(q.siklar) : [])];
  return s.map(x => String(x == null ? '' : x)).join(' \n ');
}
function r1(q) { const t = metin(q); return R1_RX.filter(([rx]) => rx.test(t)).map(([, ad]) => ad); }
function sayiSik(v) { const t = String(v == null ? '' : v).trim(); return /^[-+]?[\d.,\s%₺TL]+$/.test(t) && /\d/.test(t); }
function r4(q) { const s = q.siklar ? Object.values(q.siklar) : []; return s.filter(sayiSik).length >= 4; }

function tara() {
  const secDir = path.join(KOK, 'veri', 'sinav', 'kaydir-secim');
  const secim = [];
  for (const f of fs.readdirSync(secDir).filter(f => /^yayin-sgs-.*\.json$|^vitrin-sgs-secim\.json$/.test(f)))
    for (const r of oku(path.join(secDir, f))) if (r && r.etiket && r.id) secim.push({ etiket: r.etiket, id: r.id, sayfa: f.replace(/^yayin-sgs-|\.json$/g, ''), ders: r.ders || '' });
  const tekil = new Map(); for (const s of secim) { const k = s.etiket + '/' + s.id; if (!tekil.has(k)) tekil.set(k, s); }
  const mulgaY = path.join(KOK, 'veri', 'sinav', 'ambar-mulga-maddeler.json');
  const mulga = new Set(fs.existsSync(mulgaY) ? oku(mulgaY).maddeler.map(m => m.kaynak_ad) : []);
  const degY = path.join(KOK, 'veri', 'sinav', 'mevzuat-degisti-degmeyen.json');
  const degmeyen = new Map(); if (fs.existsSync(degY)) for (const k of oku(degY).kayitlar || []) if (k.anahtar && /^sgs-/.test(k.anahtar)) degmeyen.set(k.anahtar, k.madde || '');
  const ret = new Set(Object.keys((oku(path.join(KOK, 'veri', 'sinav', 'sgs-elle-ret.json')).kayitlar) || {}));
  const partiOnbellek = new Map();
  const parti = e => { if (!partiOnbellek.has(e)) { const p = path.join(KOK, 'veri', 'fabrika', 'kalip-parti-' + e + '.json'); partiOnbellek.set(e, fs.existsSync(p) ? oku(p) : null); } return partiOnbellek.get(e); };
  const satir = []; const say = { R1: 0, R2: 0, R3: 0, R4: 0, R5: 0 }; let retteki = 0;
  for (const [k, s] of tekil) {
    if (ret.has(k)) { retteki++; continue; }
    const p = parti(s.etiket); const q = p && p[s.id];
    const sin = [], neden = [];
    if (!q) { sin.push('R5'); neden.push('yerel partide kayıt yok'); }
    else {
      const a = r1(q); if (a.length) { sin.push('R1'); neden.push('R1: ' + a.join(', ')); }
      const m = (q.kaynak_adlar || []).filter(x => mulga.has(x)); if (m.length) { sin.push('R2'); neden.push('R2: ' + m.join('; ')); }
      if (degmeyen.has(k)) { sin.push('R3'); neden.push('R3: ' + degmeyen.get(k)); }
      if (r4(q)) sin.push('R4');
    }
    sin.forEach(x => say[x]++);
    if (sin.length) satir.push({ anahtar: k, sayfa: s.sayfa, siniflar: sin, neden: neden.join(' | '), oncelik: sin.includes('R2') || sin.includes('R3') ? 1 : sin.includes('R1') ? 2 : sin.includes('R5') ? 2 : 3 });
  }
  satir.sort((a, b) => a.oncelik - b.oncelik || a.anahtar.localeCompare(b.anahtar));
  const ozet = { taranan: tekil.size, elle_rette_atlanan: retteki, siniflar: say, oncelik1: satir.filter(x => x.oncelik === 1).length, oncelik2: satir.filter(x => x.oncelik === 2).length, oncelik3: satir.filter(x => x.oncelik === 3).length,
    taranmayan: 'anlam/mantık hatası (hesapsız, yıl-bağsız sözel soru) · ambar-yerel parti farkı · seçimden sonra düşen soru' };
  return { ozet, satir };
}

if (process.argv.includes('--sinav')) {
  const V = [
    ['asgari ücret', { soru: '2026 yılı asgari ücret brüt tutarı esas alınarak hesaplayınız.', siklar: { A: 'a', B: 'b', C: 'c', D: 'd', E: 'e' } }, true, false],
    ['had + tutar', { soru: 'Fatura düzenleme sınırı 12.000 TL olarak uygulanır.', siklar: { A: 'a', B: 'b', C: 'c', D: 'd', E: 'e' } }, true, false],
    ['sözel soru', { soru: 'Anonim şirketin organları hangileridir?', siklar: { A: 'Genel kurul', B: 'Müdür', C: 'Ortak', D: 'Sermaye', E: 'Kâr' } }, false, false],
    ['hesaplı', { soru: 'Net kâr kaçtır?', siklar: { A: '10.000', B: '12.500', C: '15.000', D: '17.500', E: '20.000' } }, false, true],
    ['yüzde şıklı hesaplı', { soru: 'Cari oran kaçtır?', siklar: { A: '%10', B: '%20', C: '%30', D: '%40', E: 'Hiçbiri' } }, false, true],
  ];
  let ok = 0;
  for (const [ad, q, b1, b4] of V) { const g1 = r1(q).length > 0, g4 = r4(q); const iyi = g1 === b1 && g4 === b4; if (iyi) ok++; console.log((iyi ? '  ✓ ' : '  ✗ ') + ad + ` → R1 ${g1} R4 ${g4}`); }
  console.log(`RİSK TARAMA ÖZ-SINAVI ${ok === V.length ? 'YEŞİL' : 'KIRMIZI'} (${ok}/${V.length})`); process.exit(ok === V.length ? 0 : 1);
} else {
  const { ozet, satir } = tara();
  fs.writeFileSync(path.join(KOK, 'veri', 'sinav', 'sgs-risk-taramasi.json'), JSON.stringify({ aciklama: 'SGS yayın risk taraması (arac/sgs-risk-tarama.js). Liste elle OKUNACAK soruları gösterir; listede olmamak "temiz" demek DEĞİL.', olcum: new Date().toISOString().slice(0, 10), ozet, satir }, null, 1) + '\n');
  console.log(JSON.stringify(ozet));
}
