#!/usr/bin/env node
/* ============================================================================
   TETİKTE 20 SÖZ · 20 SAYFALIK KAYDIRMALI GÖNDERİ (01.11.2026, Cem "sitemize övgü… 20 tane yap").
   Marka sesi (müşteri yorumu DEĞİL); her cümlenin dayanağı md yorumunda. Şablon uye-yorumlari-kaydirma.html (soz kipi).
   METİN KAPISI: her yazı pazarlama/reklam/instagram-tetikte-20-soz.md satırlarından (exit 3).
   TAŞMA KAPISI: içerik sayfa alanına sığmalı, yazı yan 40 px'e girmemeli (exit 4).
   Kullanım: node arac/video/tellal/tetikte-20-soz.js → <kasa>/tellal-reklam/TETIKTE-20-SOZ-S01..S20.png
   🚫 GÖRMEZ: cümlenin hukuki yorumu (reklam metni kapısı + insan) · özelliklerin yarın da sitede kalıp kalmadığı.
   ============================================================================ */
'use strict';
const fs = require('fs'), path = require('path');
let chromium; try { ({ chromium } = require('playwright')); } catch (e) { ({ chromium } = require('C:/Users/cemdi/.claude/araclar/kayit/node_modules/playwright')); }

const KOK = path.resolve(__dirname, '..', '..', '..');
const CIKTI = path.join('C:/Users/cemdi/OneDrive/Masaüstü/mevzuat işi', '_yerel-veri-kasasi', 'tellal-reklam');
const md = fs.readFileSync(path.join(KOK, 'pazarlama', 'reklam', 'instagram-tetikte-20-soz.md'), 'utf8');
const SATIR = {}; for (const m of md.matchAll(/^(\d+)\. (.+)$/gm)) SATIR[m[1]] = m[2].trim();
const S = n => { if (!SATIR[n]) { console.error(`METİN KAPISI: md'de ${n}. satır yok`); process.exit(3); } return SATIR[n]; };
const SAYFALAR = [];
for (let i = 1; i <= 19; i++) SAYFALAR.push({ soz: S(i), imza: S(23).toLocaleUpperCase('tr') });
SAYFALAR.push({ soz: `${S(20)} ${S(21)}`, imza: S(22) });

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
      for (const e of s.querySelectorAll('.soz, .imza')) {
        const g = document.createRange(); g.selectNodeContents(e); const r = g.getBoundingClientRect();
        if (r.left < 40 || r.right > 1040 || r.top < 90 || r.bottom > 1260) o.push(e.className);
      }
      return o;
    });
    if (sorun.length) { console.error(`TAŞMA (sayfa ${i + 1}): ${sorun.join(', ')}`); process.exit(4); }
    const cik = path.join(CIKTI, `TETIKTE-20-SOZ-S${String(i + 1).padStart(2, '0')}.png`);
    await sayfa.screenshot({ path: cik });
  }
  await tarayici.close();
  console.log(`${SAYFALAR.length} sayfa: ${CIKTI}\\TETIKTE-20-SOZ-S01..S${SAYFALAR.length}.png`);
})().catch(e => { console.error(e); process.exit(1); });
