#!/usr/bin/env node
// DENEME SET ARŞİVİNİ GİT GEÇMİŞİNDEN DOLDURUR (11.10.2026, tek seferlik + yeniden koşulabilir).
// motor/deneme-arsiv.js arşivi bundan sonra kendisi tutar; bu betik o kurulmadan ÖNCE ezilmiş sürümleri geri getirir
// (11.10 12:00 Yeterlilik konu setleri yenilendi, yarım denemeler listede görünmüyordu).
// ⛔ Yalnız KİMLİK taşıyan set dosyası arşive girer: 04.10 öncesi SGS setleri soru metni + doğru şık taşıyordu
//    (herkese açık sızıntıydı) → içinde soru/siklar/dogru alanı olan set REDDEDİLİR, o sürüm atlanır.
// Kullanım: node arac/deneme-arsiv-doldur.js [--kuru]
const { execFileSync } = require('child_process');
const path = require('path');
const { arsiveYaz, ARSIV_TAVAN } = require('../motor/deneme-arsiv.js');
const KOK = path.join(__dirname, '..'), CIKIS = path.join(KOK, 'veri', 'deneme'), KURU = process.argv.includes('--kuru');
const git = (...a) => execFileSync('git', a, { cwd: KOK, encoding: 'utf8', maxBuffer: 64 << 20 });
const sizar = j => (j.sorular || []).some(q => q.soru || q.siklar || q.dogru);
for (const onek of ['sgs', 'sgs-sik', 'smmm-sik', 'smmm-ders']) {
  const yol = `veri/deneme/${onek}-dizin.json`;
  let simdi = null; try { simdi = JSON.parse(git('show', `HEAD:${yol}`)).surum; } catch (e) { continue; }
  const commitler = git('log', '--format=%H', '--', yol).trim().split('\n').filter(Boolean);
  const gorulen = new Set([simdi]); let alinan = 0, red = 0;
  for (const c of commitler) {
    if (alinan >= ARSIV_TAVAN) break;
    let d; try { d = JSON.parse(git('show', `${c}:${yol}`)); } catch (e) { continue; }
    if (!d.surum || gorulen.has(d.surum)) continue; gorulen.add(d.surum);
    const dosyalar = []; let bozuk = false;
    for (const s of d.setler || []) {
      let ic; try { ic = git('show', `${c}:${s.dosya}`); } catch (e) { bozuk = true; break; }
      let j; try { j = JSON.parse(ic.replace(/^﻿/, '')); } catch (e) { bozuk = true; break; }
      if (sizar(j)) { bozuk = true; red++; break; }
      dosyalar.push({ no: s.no, icerik: ic });
    }
    if (bozuk || !dosyalar.length) continue;
    const n = KURU ? dosyalar.length : arsiveYaz(CIKIS, onek, d.surum, dosyalar, true);
    console.log(`  ${onek}-${d.surum} (${c.slice(0, 8)}): ${n} set${KURU ? ' (kuru)' : ''}`); alinan++;
  }
  console.log(`${onek}: güncel ${simdi} · arşive ${alinan} eski sürüm${red ? ` · metin taşıdığı için reddedilen ${red}` : ''}`);
}
