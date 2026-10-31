#!/usr/bin/env node
/* ============================================================================
   ÜYE YORUMLARI · 4 SAYFALIK KAYDIRMALI GÖNDERİ (01.11.2026, Cem "4 sayfa olsun").
   Instagram'daki herkese açık GERÇEK yorumlar (kaynak/kimlik md yorumunda) → 4 × 1080×1350 PNG. Bedel 0.
   METİN KAPISI: her yazı pazarlama/reklam/instagram-uye-yorumlari-kaydirma.md satırlarından (exit 3).
   TAŞMA KAPISI: içerik sayfa alanına sığmalı, yazı yan 40 px'e girmemeli (exit 4).
   Kullanım: node arac/video/tellal/uye-yorumlari-kaydirma.js → <kasa>/tellal-reklam/UYE-YORUMLARI-S{1..4}.png
   🚫 GÖRMEZ: yorumun hâlâ yayında olup olmadığı · WhatsApp mesajları (erişim yok, kullanılmadı).
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const CIKTI = path.join('C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi', '_yerel-veri-kasasi', 'tellal-reklam');
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'instagram-uye-yorumlari-kaydirma.md'), 'utf8');
const SATIR = {}; for (const m of md.matchAll(/^(\d+)\. (.+)$/gm)) SATIR[m[1]] = m[2].trim();
const S = n => { if (!SATIR[n]) { console.error(`METİN KAPISI: md'de ${n}. satır yok`); process.exit(3); } return SATIR[n]; };
const kart = (y, k) => [S(y), `${S(k)} · ${S(24)}`];
const SAYFALAR = [
  { baslik: S(1), altbaslik: S(2), kartlar: [kart(3, 4), kart(5, 6)] },
  { kartlar: [kart(7, 8), kart(9, 10), kart(11, 12)] },
  { kartlar: [kart(13, 14), kart(15, 16), kart(17, 18)] },
  { son: [S(19), S(20), S(21), S(22), S(23)] },
];

(async () => {
  const tarayici = await chromium.launch();
  const url = 'file:///' + path.join(__dirname, 'uye-yorumlari-kaydirma.html').replace(/\\/g, '/');
  for (let i = 0; i < SAYFALAR.length; i++) {
    const sayfa = await tarayici.newPage({ viewport: { width: 1080, height: 1350 } });
    await sayfa.goto(url);
    await sayfa.evaluate(v => window.kur(v), { sayfa: SAYFALAR[i], sira: i, toplam: SAYFALAR.length });
    const sorun = await sayfa.evaluate(() => {
      const o = [], s = document.getElementById('sayfa');
      if (s.scrollHeight > s.clientHeight + 1) o.push(`sayfa taşıyor ${s.scrollHeight}>${s.clientHeight}`);
      for (const c of s.children) { const r = c.getBoundingClientRect(); if (r.top < 40 || r.bottom > 1260) o.push('dikey ' + c.className); }
      for (const e of s.querySelectorAll('.y, .k, .baslik, .altbaslik, .son > div')) {
        const g = document.createRange(); g.selectNodeContents(e); const r = g.getBoundingClientRect();
        if (r.left < 40 || r.right > 1040) o.push('yan ' + e.className);
      }
      return o;
    });
    if (sorun.length) { console.error(`TAŞMA (sayfa ${i + 1}): ${sorun.join(', ')}`); process.exit(4); }
    const cik = path.join(CIKTI, `UYE-YORUMLARI-S${i + 1}.png`);
    await sayfa.screenshot({ path: cik });
    console.log(cik);
  }
  await tarayici.close();
})().catch(e => { console.error(e); process.exit(1); });
