#!/usr/bin/env node
/* nobetci-notu-sinavi.js — NÖBETÇİ NOTU ÖZ-SINAVI (12.10.2026, dogrula.yml)
 * nobetci-notu.js'in GERÇEK saf işlevlerini (kopya değil) çalıştırır: 10'da bir gösterim, 20'de bir kez davet, son 10'un
 * tutulması, zayıf konu seçimi, KANITLI RAKAM (dönem sayısı = okunmuş kaynaktan doğrudan sayılan, bütün konularda) ve ek.
 * --mutasyon: üç kural bilerek bozulur (NN_MUTASYON), her bozmada sınav KIRMIZI düşmeli.
 * 🚫 GÖRMEZ: kartın çizimi / düğmeler (tarayıcı denemesi ayrı) · uygulamadaki bağ (uygulama-kaydir.js).
 */
'use strict';
const fs = require('fs'), path = require('path'), { spawnSync } = require('child_process');
const KOK = path.join(__dirname, '..');
if (process.argv.includes('--mutasyon')) {
  const M = ['her-cevap', 'esitlik', 'satir-say']; let tutan = 0;
  for (const m of M) {
    const r = spawnSync(process.execPath, [__filename], { env: Object.assign({}, process.env, { NN_MUTASYON: m }), encoding: 'utf8' });
    const k = r.status !== 0; if (k) tutan++; console.log(`  mutasyon ${m.padEnd(10)} ${k ? 'KIRMIZI (doğru)' : 'YEŞİL — SINAV KÖR'}`);
  }
  console.log(`MUTASYON: ${tutan}/${M.length} → KIRMIZI`); process.exit(tutan === M.length ? 0 : 1);
}
const S = require(path.join(KOK, 'nobetci-notu.js'));
let hata = 0; const t = (ad, k) => { console.log((k ? '  geçti: ' : '  DÜŞTÜ: ') + ad); if (!k) hata++; };

let d = null, gos = [], dav = [];
for (let i = 1; i <= 30; i++) { const r = S.ilerle(d, 'q' + i, i % 3 !== 0); d = r.durum; if (r.davet) d.davet = true; if (r.goster) gos.push(i); if (r.davet) dav.push(i); }
t('kart yalnız 10, 20, 30. cevapta', gos.join(',') === '10,20,30');
t('ders denemesi daveti yalnız 20. cevapta, bir kez', dav.join(',') === '20');
t('son 10 cevap tutulur', d.son.length === 10 && d.son[0][0] === 'q21' && d.son[9][0] === 'q30');
t('girdi değişmez (saf)', (() => { const x = { n: 3, son: [['a', 1]] }; S.ilerle(x, 'b', 0); return x.n === 3 && x.son.length === 1; })());

const idKonu = { a1: 'A', a2: 'A', b1: 'B', b2: 'B', c1: 'C' };
const kanit = { A: [['2025/3', '1'], ['2024/2', '4']], B: [['2026/1', '2'], ['2025/3', '5'], ['2024/1', '3'], ['2024/1', '7']], C: [] };
const o1 = S.ozet([['a1', 0], ['a2', 0], ['b1', 0], ['c1', 1], ['x', 0]], idKonu, kanit);
t('doğru sayısı ve toplam', o1.dogru === 1 && o1.toplam === 5);
t('zayıf konu = en çok yanlış (A 2 > B 1); konusuz yanlış sayılmaz', o1.zayif.konu === 'A' && o1.zayif.yanlis === 2);
const o2 = S.ozet([['a1', 0], ['b1', 0]], idKonu, kanit);
t('eşitlikte sınavda daha sık sorulan konu (B 3 dönem > A 2)', o2.zayif.konu === 'B');
t('hepsi doğruysa zayıf konu yok', S.ozet([['a1', 1], ['b1', 1]], idKonu, kanit).zayif === null);
t('dönem sayısı FARKLI dönemdir (4 satır, 3 dönem)', S.donemSay(kanit.B) === 3 && S.donemSay([]) === 0 && S.donemSay(null) === 0);
t('kanıt metni dönem dönem gruplanır', S.kanitMetni(kanit.B) === '2026/1: soru 2 · 2025/3: soru 5 · 2024/1: soru 3, 7');
t('ek: 25\'inde, 6\'sında, 30\'unda, 3\'ünde, 9\'unda', S.ek(25) === 'inde' && S.ek(6) === 'sında' && S.ek(30) === 'unda' && S.ek(3) === 'ünde' && S.ek(9) === 'unda');

// KANITLI RAKAM (gerçek veri): karttaki dönem sayısı = smmm-konu-okuma.json'dan doğrudan sayılan, havuzun BÜTÜN konularında
try {
  const J = f => JSON.parse(fs.readFileSync(path.join(KOK, f), 'utf8').replace(/^﻿/, ''));
  const kn = J('veri/deneme/smmm-konu-kanit.json'), ok = J('veri/sinav/smmm-konu-okuma.json'), hv = J('veri/deneme/smmm-ders-havuz.json');
  const dogrudan = {}; ok.kararlar.forEach(x => { ((dogrudan[x.ders] = dogrudan[x.ders] || {})[x.konu] = dogrudan[x.ders][x.konu] || new Set()).add(x.donem); });
  let konu = 0, ayni = 0, kanitsiz = 0;
  for (const ders of Object.keys(hv.dersler)) for (const k of hv.dersler[ders].konular) {
    if (!k) continue; konu++;
    const l = kn.dersler[ders] && kn.dersler[ders][k];
    if (!l) { kanitsiz++; continue; }
    if (S.donemSay(l) === (dogrudan[ders] && dogrudan[ders][k] ? dogrudan[ders][k].size : -1)) ayni++;
  }
  t(`gerçek veri: ${konu} konunun ${ayni}'inde karttaki rakam = okunmuş kaynaktan doğrudan sayım (kanıtsız ${kanitsiz})`, konu > 200 && ayni === konu - kanitsiz);
  t('kanıt dosyasının penceresi ve sınav sayısı kaynakla aynı', kn.pencere === ok.pencere && kn.donem === ok.donem);
} catch (e) { t('gerçek veri okunamadı: ' + e.message, false); }

console.log(hata ? `ÖZ-SINAV DÜŞTÜ (${hata})` : 'ÖZ-SINAV GEÇTİ');
process.exit(hata ? 1 : 0);
