#!/usr/bin/env node
/*
================================================================================
  SINAV PROVASI KONU AĞIRLIĞI — 15.10.2026 (Cem: "en çok çıkan sınav konularından bir hazırlık yapalım,
  ders ders tutsun, gerçek sınavla yaparsan sevinirim")
  bedel 0 (model yok, ağ yok — yalnız depodaki tablolar)

  motor/canli-paketle.ps1 kasadaki aday soruları (id, ders, konu) bir dosyaya yazar; bu araç her soruya
  KONUSUNUN SON 10 YILDA KAÇ SORU ÇIKARDIĞINI ve kaç dönemde çıktığını ekler. Paketleyici bu ağırlıkla seçer.

  SGS  : konu etiketi → veri/sinav/sgs-konu-es.json kümesi → veri/fabrika/sgs-konu-kapsama.csv (2016+, 32 dönem)
         (eşleme mantığı arac/sgs-konu-kapsama.js ile aynı: önce etiketin kendisi, sonra sözlükteki küme başı)
  SMMM : soru kimliği → veri/sinav/smmm-banka-esleme.json okunmuş konular → veri/fabrika/smmm-okunmus-kapsama.csv
         (birden çok konu varsa en sık olanı)

  🚫 GÖRMEZ: tablolar bayatsa (yeni dönem yutulmadıysa) son dönemin sıklığı · eşlemesi olmayan soru (son=0, "eşleşmeyen"
     sayılır, paketleyici en sona bırakır) · kümeleme/okuma hatası (örneklemle ölçüldü, tamamı okunmadı).

  KULLANIM: node arac/prova-konu-agirlik.js <sgs|smmm> <aday.json> <cikti.json>
            node arac/prova-konu-agirlik.js --sinav     (öz-sınav)
================================================================================
*/
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.resolve(__dirname, '..');
const oku = p => fs.readFileSync(path.isAbsolute(p) ? p : path.join(KOK, p), 'utf8').replace(/^﻿/, '');

function katla(s) {
  let t = String(s).replace(/İ/g, 'I').replace(/ı/g, 'i').toLowerCase();
  t = t.replace(/i̇/g, 'i').replace(/ş/g, 's').replace(/ğ/g, 'g').replace(/ü/g, 'u').replace(/ö/g, 'o').replace(/ç/g, 'c')
    .replace(/[âà]/g, 'a').replace(/î/g, 'i').replace(/û/g, 'u').replace(/['’]/g, '');
  return t.replace(/[^a-z0-9 ]/g, ' ').replace(/\s+/g, ' ').trim();
}
function csv(t, ay) {
  return t.split(/\r?\n/).filter(Boolean).map(l => {
    const o = []; let c = '', q = false;
    for (let i = 0; i < l.length; i++) {
      const h = l[i];
      if (q) { if (h === '"' && l[i + 1] === '"') { c += '"'; i++; } else if (h === '"') q = false; else c += h; }
      else if (h === '"') q = true; else if (h === ay) { o.push(c); c = ''; } else c += h;
    }
    o.push(c); return o;
  });
}

function sgsBulucu() {
  const es = JSON.parse(oku('veri/sinav/sgs-konu-es.json')).esleme;
  const lab = new Map();
  for (const r of csv(oku('veri/fabrika/sgs-konu-kapsama.csv'), ';').slice(1)) {
    const v = { kume: r[0] + '|' + r[1], son: +r[3] || 0, don: +r[4] || 0 };
    [r[1], ...String(r[2] || '').split(' | ')].filter(Boolean).forEach(x => { const k = katla(x); if (!lab.has(k)) lab.set(k, v); });
  }
  return s => {
    const a = katla(s.konu);
    if (lab.has(a)) return lab.get(a);
    if (es[a] && lab.has(katla(es[a].k))) return lab.get(katla(es[a].k));
    return null;
  };
}
function smmmBulucu() {
  const be = JSON.parse(oku('veri/sinav/smmm-banka-esleme.json')).sorular;
  const okm = new Map();
  for (const r of csv(oku('veri/fabrika/smmm-okunmus-kapsama.csv'), ',').slice(1)) okm.set(r[0] + '|' + r[1], { kume: r[0] + '|' + r[1], son: +r[3] || 0, don: +r[2] || 0 });
  return s => {
    const e = be[s.id]; if (!e) return null;
    let b = null;
    for (const k of e.konular || []) { const v = okm.get(e.ders + '|' + k); if (v && (!b || v.son > b.son)) b = v; }
    return b;
  };
}

function agirlik(sinav, adaylar) {
  const bul = sinav === 'sgs' ? sgsBulucu() : smmmBulucu();
  const out = {};
  for (const s of adaylar) {
    const r = bul(s);
    out[s.id] = r ? { kume: r.kume, son: r.son, don: r.don } : { kume: 'YOK|' + s.id, son: 0, don: 0 };
  }
  return out;
}

function sinav() {
  let h = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) h++; };
  const s = agirlik('sgs', [{ id: 'a', ders: 'Atatürk İlkeleri ve İnkılap Tarihi', konu: 'Lozan Konferansı' },
    { id: 'b', ders: 'X', konu: 'boyle bir konu yok qwz' }]);
  t('SGS: arşiv etiketi kümeye bağlanır (Lozan, son10 > 0)', s.a.son > 0 && /lozan/.test(s.a.kume));
  t('SGS: eşleşmeyen konu son=0 ve kendi kümesi', s.b.son === 0 && s.b.kume === 'YOK|b');
  const be = JSON.parse(oku('veri/sinav/smmm-banka-esleme.json')).sorular;
  const id = Object.keys(be)[0];
  const m = agirlik('smmm', [{ id }, { id: 'yok/kp-00' }]);
  t('SMMM: banka eşlemesi olan soru okunmuş konuya bağlanır', m[id].kume !== 'YOK|' + id);
  t('SMMM: eşlemesiz kimlik son=0', m['yok/kp-00'].son === 0);
  console.log(h ? `KIRMIZI (${h})` : 'YEŞİL'); process.exit(h ? 1 : 0);
}

if (require.main === module) {
  if (process.argv[2] === '--sinav') sinav();
  const [, , sv, giris, cikis] = process.argv;
  if (!/^(sgs|smmm)$/.test(sv || '') || !giris || !cikis) { console.error('kullanim: <sgs|smmm> <aday.json> <cikti.json>'); process.exit(2); }
  const adaylar = JSON.parse(oku(giris));
  const a = agirlik(sv, adaylar);
  fs.writeFileSync(cikis, JSON.stringify(a));
  const v = Object.values(a); console.log(`agirlik: ${v.length} aday · eslesen ${v.filter(x => x.son > 0).length}`);
}
module.exports = { agirlik, katla };
