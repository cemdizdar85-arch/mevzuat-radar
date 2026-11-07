#!/usr/bin/env node
// ============================================================================
//  BAG DIZINI — yalniz ISTENEN kaynak adlarina bagli soru kayitlarini bulur (07.11.2026, A-11, Cem onayi)
//  NIYE: motor/mevzuat-yut.ps1 BagDizini, SMMM/SGS/KGK kalip_parti'nin TAMAMINI (07.11: 32.637 satir, ~445 MB icerik) PowerShell 5.1'de
//    ConvertFrom-Json ile ayristirip butun adlarin dizinini kuruyordu. 07.11 pilot yutmasinda makine bellegi kritik dustu, is durduruldu
//    (ambar yazilmadan; yedekle birebir ayni kaldi). Bu arac sayfa sayfa okur, YALNIZ istenen adlari tutar, sayfayi birakir.
//  CIKTI: { "<kaynak_ad>": ["<SINAV> <etiket>/<kp>", ...] }  — BagDizini'nin eski bicimiyle AYNI (ana akis kimligi 2. alandan alir).
//  KULLANIM:
//    node arac/bag-dizini.js --adlar <adlar.json> --cikti <dizin.json>     (adlar.json: ["ad", ...])
//    node arac/bag-dizini.js --sinav                                       oz-sinav (sahte ambar, ag yok) + mutasyon
//  YALNIZ OKUR. Anahtar ekrana/dosyaya yazilmaz.
//  🚫 GORMEZ: SMMM/SGS/KGK disi partiler (eski BagDizini ile ayni suzgec) · kaynak_adlar disindaki alanlarda gecen ad ·
//    okuma sirasinda yazilan parti (anlik goruntu degil; kosullu yazim yaris'i ayrica yakalar).
// ============================================================================
'use strict';
const fs = require('fs'), cp = require('child_process');
const TABAN = 'https://bjrleanjpyujtajmazxn.supabase.co/rest/v1';
const MUT = process.env.BAG_DIZIN_MUTASYON || '';
const SINAVLAR = ['SMMM', 'SGS', 'KGK'];

async function dizinKur(io, adlar) {
  const iste = new Set(adlar.map(String)); const d = {};
  if (!iste.size && MUT !== 'bos-tara') return d;
  for (let ofs = 0; ; ofs += io.adim) {
    const sayfa = await io.sayfa(ofs);
    for (const pr of sayfa) {
      if (MUT !== 'sinav-yok' && !SINAVLAR.includes(String(pr.sinav))) continue;
      let ic = pr.icerik; if (typeof ic === 'string') ic = JSON.parse(ic); if (!ic) continue;
      for (const [kp, v] of Object.entries(ic)) {
        if (!v || !Array.isArray(v.kaynak_adlar)) continue;
        for (const ka of v.kaynak_adlar) { const s = String(ka || ''); if (!s) continue; if (MUT !== 'suzgec-yok' && !iste.has(s)) continue; (d[s] = d[s] || []).push(`${pr.sinav} ${pr.etiket}/${kp}`); }
      }
    }
    if (sayfa.length < io.adim) break;
  }
  return d;
}
function gercekIO() {
  const K = (process.env.SUPABASE_SERVICE_KEY || (process.platform === 'win32' ? (cp.spawnSync('powershell', ['-NoProfile', '-Command', "[Environment]::GetEnvironmentVariable('SUPABASE_SERVICE_KEY','User')"], { encoding: 'utf8' }).stdout || '') : '')).trim();
  if (!K) throw new Error('SUPABASE_SERVICE_KEY yok');
  const h = { apikey: K, Authorization: 'Bearer ' + K, 'User-Agent': 'mevzuat-radar-robot/1.0' };
  return { adim: 25, async sayfa(ofs) { for (let d = 1; d <= 4; d++) { try { const r = await fetch(`${TABAN}/kalip_parti?select=etiket,sinav,icerik&sinav=in.(SMMM,SGS,KGK)&order=etiket.asc&limit=25&offset=${ofs}`, { headers: h, signal: AbortSignal.timeout(180000) }); if (!r.ok) throw new Error('ambar ' + r.status); return await r.json(); } catch (e) { if (d === 4) throw e; await new Promise(z => setTimeout(z, 2000 * d)); } } } };
}
function sahteIO(P, adim = 2) { let n = 0; return { adim, istek: () => n, async sayfa(ofs) { n++; return P.slice(ofs, ofs + adim); } }; }

async function sinav() {
  let ok = 0, top = 0; const S = (ad, g) => { top++; if (g) ok++; console.log((g ? '  ✓ ' : '  ✗ ') + ad); };
  const P = [
    { etiket: 'kgk-a', sinav: 'KGK', icerik: { 'kp-01': { kaynak_adlar: ['K m.45 - Kirli. Tarh zamanı', 'K m.1'] } } },
    { etiket: 'sgs-b', sinav: 'SGS', icerik: JSON.stringify({ 'kp-02': { kaynak_adlar: ['K m.45 - Kirli. Tarh zamanı'] }, 'kp-03': { soru: 'x' } }) },
    { etiket: 'smmm-c', sinav: 'SMMM', icerik: { 'kp-04': { kaynak_adlar: ['K m.2'] } } },
    { etiket: 'spl-d', sinav: 'SPL', icerik: { 'kp-05': { kaynak_adlar: ['K m.45 - Kirli. Tarh zamanı'] } } },
    { etiket: 'smmm-e', sinav: 'SMMM', icerik: { 'kp-06': { kaynak_adlar: ['K m.45 - Kirli. Tarh zamanı', null] } } }];
  { const d = await dizinKur(sahteIO(P), ['K m.45 - Kirli. Tarh zamanı']);
    S('yalniz istenen ad dondu (K m.1 / K m.2 YOK)', Object.keys(d).join('|') === 'K m.45 - Kirli. Tarh zamanı');
    S('SMMM/SGS/KGK kayitlari bulundu, eski bicim "SINAV etiket/kp"', (d['K m.45 - Kirli. Tarh zamanı'] || []).join('|') === 'KGK kgk-a/kp-01|SGS sgs-b/kp-02|SMMM smmm-e/kp-06');
    S('SPL (suzgec disi) sayilmadi', !(d['K m.45 - Kirli. Tarh zamanı'] || []).some(x => x.startsWith('SPL'))); }
  { const io = sahteIO(P); const d = await dizinKur(io, []); S('bos istek: ambara HIC gidilmez, bos dizin', Object.keys(d).length === 0 && io.istek() === 0); }
  { const io = sahteIO(P, 2); await dizinKur(io, ['K m.2']); S('sayfalama: 5 satir / 2lik sayfa -> 3 istek, sonda durur', io.istek() === 3); }
  console.log(`ÖZ-SINAV ${ok}/${top}`); return ok === top;
}

(async () => {
  const a = process.argv;
  if (a[2] === '--sinav') { const g = await sinav();
    if (!MUT) { let hepsi = true;
      for (const m of ['suzgec-yok', 'sinav-yok', 'bos-tara']) { const c = cp.spawnSync(process.execPath, [__filename, '--sinav'], { env: { ...process.env, BAG_DIZIN_MUTASYON: m }, encoding: 'utf8' });
        const yak = c.status !== 0 && /ÖZ-SINAV \d+\/\d+/.test(c.stdout) && /✗/.test(c.stdout); hepsi = hepsi && yak; console.log((yak ? '  ✓ ' : '  ✗ ') + 'MUTASYON ' + m + ' YAKALANDI'); }
      process.exit(g && hepsi ? 0 : 1); }
    process.exit(g ? 0 : 1); }
  const ai = a.indexOf('--adlar'), ci = a.indexOf('--cikti');
  if (ai < 0 || ci < 0) { console.error('kullanim: --adlar <adlar.json> --cikti <dizin.json> | --sinav'); process.exit(2); }
  const adlar = JSON.parse(fs.readFileSync(a[ai + 1], 'utf8').replace(/^﻿/, ''));
  const d = await dizinKur(gercekIO(), Array.isArray(adlar) ? adlar : []);
  fs.writeFileSync(a[ci + 1], JSON.stringify(d));
  console.log(`BAG DIZINI: istenen ad ${adlar.length} · bagli ad ${Object.keys(d).length} · kayit ${Object.values(d).reduce((n, x) => n + x.length, 0)}`);
})().catch(e => { console.error('HATA', e.message); process.exit(1); });
