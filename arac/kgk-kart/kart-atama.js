// KARTTAN dalga ataması (standart K1/K2/K4/K8; DEVIR §3). Bedel 0.
// Yalnız 4 alanı DOLU ve dayanağı "AMBARDA YOK / BOZUK / OKUNAMADI" ile BAŞLAMAYAN kart. Sıra: son10 ↓, eksik ↓ (K2).
// Konu başına adet = min(eksik, --konu-basi); kalıp = kartın gerçek dağılımı oranında, site + yeni birlikte gerçeğe yaklaşır;
//   gerçekte 2+ görülüp bankada olmayan kalıp önce; gerçekte görülmemiş kalıp YOK. Aynı dosyada bir konu bir kez (AYNI KONU kapısı).
// GÖRMEZ: site kalıp sayımı kalip/site-konu-kalip.json (03.11 anlık) · kart konusuna yanlış bağlanmış çıkmış soru (kalıp sayımını bozar; yazım notuna bakılır).
// node kart-atama.js <KOD> <grup> <toplam> [--konu-basi 2] [--yaz]
'use strict';
const fs = require('fs'), path = require('path'); const IS = path.join(__dirname, '..'), oku = p => JSON.parse(fs.readFileSync(p, 'utf8').replace(/^﻿/, ''));
const a = process.argv.slice(2), [kod, grup, topS] = a, opt = (k, d) => { const i = a.indexOf(k); return i >= 0 ? a[i + 1] : d; };
const KB = +opt('--konu-basi', 2), TOP = +topS, YAZ = a.includes('--yaz');
const K = oku(path.join(__dirname, 'kartlar', `${kod}.json`)), S = oku(path.join(IS, 'kalip', 'site-konu-kalip.json')).konu || {};
const ALAN = ['ne_sorar', 'dayanak', 'celdirici', 'yazim_notu'];
// --onceki <grup1,grup2>: önceki partilerin yazılmış soruları (hazır dosyadaki konu sayısı) eksikten düşülür; kalıpları siteye eklenmiş sayılır.
const ONC = (opt('--onceki', '') || '').split(',').filter(Boolean), DUS = {}, SEK = {};
for (const g of ONC) for (const z of ['kolay', 'zor', 'cokzor']) { const f = 'C:/TETIKTE-CALISMA/kgk-basim/veri/fabrika/hazir-kgk-t10-' + g + '-' + z + '.json'; if (!fs.existsSync(f)) continue; const { ayir } = require(path.join(IS, 'kalip', 'kgk-kalip-ayirici.js')); for (const q of oku(f)) { DUS[q.konu] = (DUS[q.konu] || 0) + 1; const h = ayir(String(q.soru || ''), Object.values(q.siklar || {}).map(String)); (SEK[q.konu] ||= {})[h] = (SEK[q.konu][h] || 0) + 1; } }
for (const c of K) if (DUS[c.konu]) c.eksik = Math.max(0, (c.eksik || 0) - DUS[c.konu]);
for (const [k, v] of Object.entries(SEK)) { S[k] = { ...(S[k] || {}) }; for (const [h, n] of Object.entries(v)) S[k][h] = (S[k][h] || 0) + n; }
const uygun = K.filter(c => ALAN.every(k => String(c[k] || '').trim()) && !/^\s*(AMBARDA YOK|BOZUK|OKUNAMADI)/.test(c.dayanak) && (c.eksik || 0) > 0)
  .sort((x, y) => (y.son10 || 0) - (x.son10 || 0) || (y.eksik || 0) - (x.eksik || 0));
const sec = []; let n = 0;
for (const c of uygun) {
  if (n >= TOP) break; const g = c.kalip_dagilim, gT = Object.values(g).reduce((p, q) => p + q, 0); if (!gT) continue;
  const s = S[c.konu] || {}, sT = Object.keys(g).reduce((p, h) => p + (s[h] || 0), 0), yeni = {}, L = [], banka = h => (s[h] || 0) + (yeni[h] || 0);
  const adet = Math.min(c.eksik, KB, TOP - n);
  for (let i = 0; i < adet; i++) {
    let h = Object.keys(g).filter(x => g[x] >= 2 && !banka(x)).sort((x, y) => g[y] - g[x])[0];
    if (!h) { const T = sT + i + 1; h = Object.keys(g).sort((x, y) => (g[y] / gT * T - banka(y)) - (g[x] / gT * T - banka(x)) || g[y] - g[x])[0]; }
    yeni[h] = (yeni[h] || 0) + 1; L.push(h);
  }
  sec.push({ c, L }); n += L.length;
}
const Z = ['kolay', 'zor', 'cokzor'], H = 'ABCDE'; let zi = 0; const say = { kolay: 0, zor: 0, cokzor: 0 };
const sat = [`KART ATAMASI — ${grup} (kart/kart-atama.js; KGK-KONU-KARTLARI.md). Her soru kartına + atanan kalıba göre yazılır. Atama dışı kalıp YAZILMAZ.`];
const harf = [`HARF PLANI (${sec.length} konu):`];
sec.forEach(({ c, L }, i) => {
  // zorluk dağılımı kolay %25 · zor %50 · çok zor %25 (CLAUDE.md bitirme 6) — konu içinde farklı dosya
  const zz = L.map((_, j) => { const sira = ['zor', 'kolay', 'zor', 'cokzor']; return sira[(zi + j) % 4]; }); zi += L.length;
  if (new Set(zz).size < zz.length) zz[1] = zz[0] === 'zor' ? 'cokzor' : 'zor';
  zz.forEach(z => say[z]++);
  sat.push(`  ${c.konu} → ${L.map((h, j) => `${zz[j]}: ${h}`).join(' · ')}   [kart: ${c.kalip.join(' / ')} · sitede ${JSON.stringify(S[c.konu] || {})} · kök ${c.kok_hedef_kr ? c.kok_hedef_kr.join('–') : '?'} kr · son10 ${c.son10} · eksik ${c.eksik}]`);
  harf.push(`  ${c.konu} → ${L.map((h, j) => `${zz[j]} ${H[(i * 2 + j * 3 + zi) % 5]}`).join(' · ')}`);
});
sat.push(`  toplam ${n} · kolay ${say.kolay} · zor ${say.zor} · cokzor ${say.cokzor} · uygun kart ${uygun.length}`);
console.log(sat.join('\n'));
if (YAZ) { fs.writeFileSync(path.join(IS, 'konu', `${grup}.json`), JSON.stringify(sec.map(x => x.c.konu), null, 1) + '\n'); fs.writeFileSync(path.join(IS, 'konu', `atama-${grup}.txt`), sat.join('\n') + '\n'); fs.writeFileSync(path.join(IS, 'konu', `harf-${grup}.txt`), harf.join('\n') + '\n'); console.log('yazıldı'); }
