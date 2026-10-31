#!/usr/bin/env node
/* ============================================================================
   ÜYE YORUMLARI GÖRSELİ (01.11.2026, Cem "üyelerimizden gelen mesajlar tarzı bir şey" → uydurma yerine GERÇEK yorum).
   Instagram'daki herkese açık gerçek yorumlar (kaynak ve kimlik md'nin yorumunda) → gönderi 1080×1350 + hikâye 1080×1920.
   METİN KAPISI: her yazı pazarlama/reklam/instagram-uye-yorumlari.md "Ekrandaki yazı" satırlarından (exit 3).
   TAŞMA KAPISI: hiçbir yazı yan 40 px'e ya da tuval altına taşmaz, kartlar üst üste binmez (exit 4).
   Kullanım: node arac/video/tellal/uye-yorumlari.js → <kasa>/tellal-reklam/UYE-YORUMLARI-{GONDERI-4x5,HIKAYE}.png
   🚫 GÖRMEZ: yorumun hâlâ yayında olup olmadığı (yayından önce gönderiye bakılır) · yorum sahibinin üyeliği (yalnız yorumcu).
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const CIKTI = path.join('C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi', '_yerel-veri-kasasi', 'tellal-reklam');
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'instagram-uye-yorumlari.md'), 'utf8');
const SATIR = {}; for (const m of md.matchAll(/^(\d+)\. (.+)$/gm)) SATIR[m[1]] = m[2].trim();
const S = n => { if (!SATIR[n]) { console.error(`METİN KAPISI: md'de ${n}. satır yok`); process.exit(3); } return SATIR[n]; };
const V = {}; for (let i = 1; i <= 11; i++) V['s' + i] = S(i);

(async () => {
  const tarayici = await chromium.launch();
  const url = 'file:///' + path.join(__dirname, 'uye-yorumlari.html').replace(/\\/g, '/');
  for (const [ad, h, hikaye] of [['GONDERI-4x5', 1350, false], ['HIKAYE', 1920, true]]) {
    const sayfa = await tarayici.newPage({ viewport: { width: 1080, height: h } });
    await sayfa.goto(url);
    await sayfa.evaluate(v => window.kur(v), { ...V, hikaye });
    const sorun = await sayfa.evaluate(H => {
      const o = [], kartlar = [...document.querySelectorAll('.kart, .alt')].map(e => e.getBoundingClientRect());
      for (let i = 1; i < kartlar.length; i++) if (kartlar[i].top < kartlar[i - 1].bottom + 12) o.push(`binme ${i}`);
      for (const e of document.querySelectorAll('.baslik, .y, .k, .alt, .adres')) {
        const g = document.createRange(); g.selectNodeContents(e); const r = g.getBoundingClientRect();
        if (r.left < 40 || r.right > 1040 || r.bottom > H - 16) o.push(e.id || e.className);
      }
      return o;
    }, h);
    if (sorun.length) { console.error(`TAŞMA (${ad}): ${sorun.join(', ')}`); process.exit(4); }
    const cik = path.join(CIKTI, `UYE-YORUMLARI-${ad}.png`);
    await sayfa.screenshot({ path: cik });
    console.log(cik);
  }
  await tarayici.close();
})().catch(e => { console.error(e); process.exit(1); });
