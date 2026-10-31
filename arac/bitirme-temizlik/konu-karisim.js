// Konu içi kalıp karışımı: gerçek 2026 testinde ≥2 sorusu olan konular kaç farklı kalıpla sorulmuş ↔ sitede her konu kaç farklı kalıpla.
// Salt okuma, bedel 0. Site konusu paket_soru.konu (bizim etiket), gerçek konu smmm-konu-okuma (okunmuş).
const fs = require('fs'), path = require('path'); const { ayir } = require('./kalip-ayirici.js');
const D = path.join(__dirname, '..', '..', 'veri', 'sinav'); const J = f => JSON.parse(fs.readFileSync(path.join(D, f), 'utf8').replace(/^﻿/, ''));
const ok = J('smmm-konu-okuma.json'), elle = J('bitirme-kalip-elle-320.json');
const KOD = { 'Finansal Muhasebe': '01', 'Finansal Tablolar ve Analizi': '02', 'Maliyet Muhasebesi': '03', 'Muhasebe Denetimi': '04', 'Vergi Mevzuatı ve Uygulaması': '05', 'Hukuk': '06', 'Meslek Hukuku': '07', 'Sermaye Piyasası Mevzuatı': '08' };
// GERÇEK
const g = {}; for (const r of ok.kararlar) { if (!r.donem.startsWith('2026')) continue; const h = (elle[`${KOD[r.ders]}|${r.donem}`] || '')[parseInt(r.soru, 10) - 1]; if (!h) continue; ((g[r.ders] ||= {})[r.konu] ||= []).push(h); }
const gOzet = {}; for (const [d, ks] of Object.entries(g)) { const coklu = Object.values(ks).filter(a => a.length >= 2); gOzet[d] = { konu_2plus: coklu.length, tek_kalip: coklu.filter(a => new Set(a).size === 1).length, ort_farkli: coklu.length ? +(coklu.reduce((s, a) => s + new Set(a).size, 0) / coklu.length).toFixed(2) : 0 }; }
console.log('GERÇEK 2026 (konu başına ≥2 soru):'); console.table(gOzet);
// SİTE
const K = process.env.SUPABASE_SERVICE_KEY, h = { apikey: K, Authorization: 'Bearer ' + K };
(async () => {
  const tum = []; for (let off = 0; ; off += 1000) { const r = await fetch(`https://bjrleanjpyujtajmazxn.supabase.co/rest/v1/paket_soru?select=id,ders,konu,veri->soru,veri->siklar&sinav=eq.smmm&order=id&limit=1000&offset=${off}`, { headers: h }).then(r => r.json()); tum.push(...r); if (r.length < 1000) break; }
  const s = {}; for (const q of tum) { if (!q.konu) continue; ((s[q.ders] ||= {})[q.konu] ||= []).push(ayir(String(q.soru || ''), Object.values(q.siklar || {}))); }
  const sOzet = {}; for (const [d, ks] of Object.entries(s)) { const c = Object.values(ks).filter(a => a.length >= 5); const tek = c.filter(a => { const m = {}; a.forEach(x => m[x] = (m[x] || 0) + 1); return Math.max(...Object.values(m)) / a.length >= 0.8; }); sOzet[d] = { konu_5plus: c.length, '%80+_tek_kalip': tek.length, oran: c.length ? Math.round(100 * tek.length / c.length) + '%' : '-', ort_farkli: c.length ? +(c.reduce((t, a) => t + new Set(a).size, 0) / c.length).toFixed(2) : 0 }; }
  console.log('SİTE (konu başına ≥5 soru; bir kalıp sorularının %80+ ise "tek tip"):'); console.table(sOzet);
})();
