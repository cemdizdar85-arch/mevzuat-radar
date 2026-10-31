#!/usr/bin/env node
/* ============================================================================
   KURUCU SON GÜN GÖRSELİ (01.11.2026, Cem "benim resmimle bir yazı paylaşalım").
   Sitedeki kurucu fotoğrafı + güven cümlesi + imza → gönderi 1080×1350 ve hikâye 1080×1920. Bedel 0.
   METİN KAPISI: her yazı pazarlama/reklam/instagram-kurucu-son-gun.md "Ekrandaki yazı" satırlarından (exit 3).
   Kullanım: node arac/video/tellal/kurucu-gonderi.js → <kasa>/tellal-reklam/KURUCU-SON-GUN-{GONDERI-4x5,HIKAYE}.png
   🚫 GÖRMEZ: fotoğrafın büyütmedeki netliği (480×600 kaynak, gözle) · hikâyeye telefondan eklenen çıkartmalar.
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const CIKTI = path.join('C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi', '_yerel-veri-kasasi', 'tellal-reklam');
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'instagram-kurucu-son-gun.md'), 'utf8');
const SATIR = {}; for (const m of md.matchAll(/^(\d+)\. (.+)$/gm)) SATIR[m[1]] = m[2].trim();
const S = n => { if (!SATIR[n]) { console.error(`METİN KAPISI: md'de ${n}. satır yok`); process.exit(3); } return SATIR[n]; };
const V = { foto: 'file:///' + path.join(KOK, 'kurucu-masa.jpg').replace(/\\/g, '/') };
for (let i = 1; i <= 7; i++) V['s' + i] = S(i);

(async () => {
  const tarayici = await chromium.launch();
  const url = 'file:///' + path.join(__dirname, 'kurucu-gonderi.html').replace(/\\/g, '/');
  for (const [ad, h, hikaye] of [['GONDERI-4x5', 1350, false], ['HIKAYE', 1920, true]]) {
    const sayfa = await tarayici.newPage({ viewport: { width: 1080, height: h } });
    await sayfa.goto(url);
    await sayfa.evaluate(v => window.kur(v), { ...V, hikaye });
    await sayfa.waitForFunction(() => document.getElementById('foto').complete);
    // taşma: hiçbir yazı tuvalin dışına ya da yan 40 px'e girmez
    // (tam genişlikte ortalı kutularda kutu değil yazının kendisi ölçülür)
    const tasma = await sayfa.evaluate(H => [...document.querySelectorAll('#ic > *:not(.imza), .imza > *')].filter(e => {
      const g = document.createRange(); g.selectNodeContents(e);
      const r = e.tagName === 'IMG' ? e.getBoundingClientRect() : g.getBoundingClientRect();
      return r.left < 40 || r.right > 1040 || r.bottom > H - 20;
    }).map(e => e.className || e.id), h);
    if (tasma.length) { console.error(`TAŞMA (${ad}): ${tasma.join(', ')}`); process.exit(4); }
    const cik = path.join(CIKTI, `KURUCU-SON-GUN-${ad}.png`);
    await sayfa.screenshot({ path: cik });
    console.log(cik);
  }
  await tarayici.close();
})().catch(e => { console.error(e); process.exit(1); });
