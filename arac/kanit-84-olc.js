#!/usr/bin/env node
/* KANIT SAYFASI ÖLÇÜMÜ (23.11.2026) — sgs-21-kasim-2026-84.html'in 84 düğmesinin HEPSİ (örneklem değil) doğru soruyu açıyor mu.
 * Anonim anahtarla (ziyaretçinin gördüğü yol) rpc/kanit_sorusu: sayfadaki her data-n için dönen id = eşleşme dosyasındaki İLK id,
 * soru + 5 şık + doğru şık + açıklama dolu. Ayrıca: dışarıda kalan 16 numara ve 1–30 açılmıyor · anon paket_soru'yu okuyamıyor.
 * Kullanım: node arac/kanit-84-olc.js [eşleşme.json]  (varsayılan ../_yerel-veri-kasasi/sgs-2026-3-eslesme-84.json)
 * Ekrana soru metni basılmaz; yalnız numara, kimlik, sonuç. */
'use strict';
const fs = require('fs'), path = require('path');
const KOK = path.join(__dirname, '..');
const SB = 'https://bjrleanjpyujtajmazxn.supabase.co', KEY = 'sb_publishable_kTZpYwrL7skw8Ryj5Vs8_Q_-5_Fhkcg';
const J = JSON.parse(fs.readFileSync(process.argv[2] || path.join(KOK, '..', '_yerel-veri-kasasi', 'sgs-2026-3-eslesme-84.json'), 'utf8'));
const html = fs.readFileSync(path.join(KOK, 'sgs-21-kasim-2026-84.html'), 'utf8');
const H = { 'Content-Type': 'application/json', apikey: KEY, Authorization: 'Bearer ' + KEY };
const rpc = n => fetch(SB + '/rest/v1/rpc/kanit_sorusu', { method: 'POST', headers: H, body: JSON.stringify({ p_liste: 'sgs-2026-3', p_n: n }) }).then(r => r.json());
(async () => {
  const sayfaN = [...new Set([...html.matchAll(/data-n="(\d+)"/g)].map(m => +m[1]))].sort((a, b) => a - b);
  const bek = new Map(J.sorular.map(s => [s.n, s.site[0]]));
  let ok = 0; const hata = [];
  if (sayfaN.length !== 84) hata.push('sayfada ' + sayfaN.length + ' ayrı numara (84 bekleniyordu)');
  for (const n of sayfaN) {
    const v = await rpc(n);
    const sorun = [];
    if (!bek.has(n)) sorun.push('eşleşme dosyasında yok');
    if (v.hata) sorun.push('hata ' + v.hata);
    else {
      if (v.id !== bek.get(n)) sorun.push('id ' + v.id + ' ≠ ' + bek.get(n));
      if (!v.soru) sorun.push('soru boş');
      if (Object.keys(v.siklar || {}).length !== 5) sorun.push('şık ' + Object.keys(v.siklar || {}).length);
      if (!v.dogru || !(v.siklar || {})[v.dogru]) sorun.push('doğru şık yok');
      if (!v.aciklama) sorun.push('açıklama boş');
    }
    if (sorun.length) hata.push('Soru ' + n + ': ' + sorun.join(', ')); else ok++;
  }
  let kapali = 0; const acilan = [];
  for (const n of [...J.disarida, 1, 15, 30, 131, 0]) { const v = await rpc(n); if (v.hata === 'listede yok') kapali++; else acilan.push(n); }
  const ps = await fetch(SB + '/rest/v1/paket_soru?select=id&limit=1', { headers: H }); const psG = ps.ok ? await ps.json() : [];
  console.log('KANIT ÖLÇÜMÜ ' + new Date().toISOString());
  console.log('  sayfadaki düğme numarası: ' + sayfaN.length + ' · doğru soruyu açan: ' + ok + ' / ' + sayfaN.length);
  console.log('  liste dışı numara kapalı: ' + kapali + ' / ' + (J.disarida.length + 5) + (acilan.length ? ' · AÇILAN: ' + acilan.join(',') : ''));
  console.log('  anon paket_soru okuması: HTTP ' + ps.status + ' · ' + (Array.isArray(psG) ? psG.length : '?') + ' satır');
  hata.forEach(h => console.log('  ✗ ' + h));
  const gecti = ok === 84 && sayfaN.length === 84 && !acilan.length && !(Array.isArray(psG) && psG.length);
  console.log(gecti ? 'SONUÇ: GEÇTİ' : 'SONUÇ: KALDI'); process.exit(gecti ? 0 : 1);
})();
