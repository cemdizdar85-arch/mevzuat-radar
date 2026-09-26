#!/usr/bin/env node
/* ikon-uret.js — uygulama ikonu ve açılış ekranı kaynakları (25.09.2026)
 *
 * Kaynak: favicon.svg'nin şekilleri (amber lamba + "ı" noktası, koyu marka tabanı #1b1a18).
 * Favicon'un köşeleri yuvarlak ve SAYDAM; App Store saydam ikon kabul etmez, Android uyarlanabilir
 * ikon ön/arka katman ister. Bu yüzden şekiller burada kare zemine yeniden dizilir.
 * Çıktı: mobil/kaynak/uretilen/ (git dışı) → `npx capacitor-assets generate --assetPath kaynak/uretilen`
 * Bulutta koşar (sharp, @capacitor/assets bağımlılığıyla gelir). Yerelde gerekmez.
 */
'use strict';
const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

const CIKTI = path.join(__dirname, 'kaynak', 'uretilen');
fs.mkdirSync(CIKTI, { recursive: true });

const TABAN = '#1b1a18';
const SEKIL = `
  <defs>
    <linearGradient id="amber" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#f5a524"/><stop offset="1" stop-color="#ffc24b"/></linearGradient>
    <radialGradient id="halo" cx="50%" cy="50%" r="50%"><stop offset="55%" stop-color="#f5a524" stop-opacity=".38"/><stop offset="100%" stop-color="#f5a524" stop-opacity="0"/></radialGradient>
  </defs>
  <circle cx="27" cy="38" r="21" fill="url(#halo)"/>
  <circle cx="27" cy="38" r="13" fill="url(#amber)"/>
  <circle cx="45" cy="19" r="5.2" fill="url(#amber)"/>`;

/* 64'lük ızgaradaki şekli (şekil kutusunun merkezi ~28,36) boy × oran büyüklükte ortalar. */
function svg(boy, oran, zemin) {
  const olcek = (boy * oran) / 64;
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${boy}" height="${boy}" viewBox="0 0 ${boy} ${boy}">` +
    (zemin ? `<rect width="${boy}" height="${boy}" fill="${zemin}"/>` : '') +
    `<g transform="translate(${boy / 2} ${boy / 2}) scale(${olcek}) translate(-28 -36)">${SEKIL}</g></svg>`);
}

(async () => {
  const isler = [
    ['icon-only.png', svg(1024, 1.0, TABAN)],          // iOS + eski Android: kare, saydamsız
    ['icon-foreground.png', svg(1024, 0.62, null)],    // Android uyarlanabilir ön katman (güvenli bölge %66)
    ['icon-background.png', svg(1024, 0, TABAN)],      // Android uyarlanabilir arka katman: düz taban
    /* açılış: ana ekranın lacivert bandıyla aynı renk (26.09 kalite dili B) — ikon rengi değişmedi */
    ['splash.png', svg(2732, 0.16, '#0c1a2b')],
    ['splash-dark.png', svg(2732, 0.16, '#0c1a2b')]
  ];
  for (const [ad, girdi] of isler) {
    let is = sharp(girdi).png();
    if (ad === 'icon-only.png') is = sharp(girdi).flatten({ background: TABAN }).png();   // alfa kanalı kalmasın (App Store)
    await is.toFile(path.join(CIKTI, ad));
  }
  console.log('IKON: ' + isler.length + ' dosya → ' + path.relative(process.cwd(), CIKTI));
})().catch((e) => { console.error('IKON HATASI: ' + e.message); process.exit(1); });
